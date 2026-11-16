#!/usr/bin/env bash
# =====================================================================
#  TEL-D2-201 provider setup – ShopNow demo for Dynatrace (Ubuntu 22.04/24.04)
#  Builds 3 Java services:
#     CheckoutService :8081  ->  PaymentService :8082  ->  stripe-mock :8090
#  PaymentService contains StripeGatewayConnector.authorize() with a 5000ms
#  socket timeout that throws ConnectionTimeoutException when the fault is on.
#  Run as:  sudo bash setup_shopnow.sh
# =====================================================================
set -euo pipefail
APP=/opt/shopnow
echo ">>> [1/5] Hostname -> host-node-03"
hostnamectl set-hostname host-node-03
grep -q host-node-03 /etc/hosts || echo "127.0.1.1 host-node-03" >> /etc/hosts

echo ">>> [2/5] Installing JDK 17, Maven, curl"
apt-get update -y
apt-get install -y openjdk-17-jdk maven curl

echo ">>> [3/5] Writing source"
SRC=$APP/src/src/main/java/com/shopnow
mkdir -p $SRC $APP/src/src/main/resources
cat > $APP/src/pom.xml <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-parent</artifactId><version>3.3.5</version></parent>
  <groupId>com.shopnow</groupId><artifactId>shopnow</artifactId><version>1.0</version>
  <properties><java.version>17</java.version></properties>
  <dependencies><dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency></dependencies>
  <build><plugins><plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin></plugins></build>
</project>
EOF

cat > $SRC/ShopNowApplication.java <<'EOF'
package com.shopnow;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
@SpringBootApplication
public class ShopNowApplication { public static void main(String[] a){ SpringApplication.run(ShopNowApplication.class, a);} }
EOF

cat > $SRC/CheckoutController.java <<'EOF'
package com.shopnow;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import java.util.Map;
@RestController @ConditionalOnProperty(name="shopnow.role", havingValue="checkout")
public class CheckoutController {
  private final RestTemplate rest = new RestTemplate();
  @PostMapping("/checkout")
  public ResponseEntity<?> checkout(@RequestParam(defaultValue="ORD-1") String orderId,
                                    @RequestParam(defaultValue="49.99") String amount) {
    try {
      String r = rest.postForObject("http://localhost:8082/payments/authorize?orderId="+orderId+"&amount="+amount, null, String.class);
      return ResponseEntity.ok(Map.of("orderId", orderId, "payment", r));
    } catch (Exception e) {
      return ResponseEntity.status(502).body(Map.of("orderId", orderId, "error", "Payment failed"));
    }
  }
}
EOF

cat > $SRC/ConnectionTimeoutException.java <<'EOF'
package com.shopnow;
public class ConnectionTimeoutException extends RuntimeException {
  public ConnectionTimeoutException(String msg, Throwable cause){ super(msg, cause); }
}
EOF

cat > $SRC/StripeGatewayConnector.java <<'EOF'
package com.shopnow;
import org.springframework.stereotype.Component;
import java.net.*; import java.io.*;
@Component
public class StripeGatewayConnector {
  private static final int SOCKET_TIMEOUT_MS = 5000;
  public String authorize(String orderId, String amount) {
    try {
      HttpURLConnection c = (HttpURLConnection) new URL("http://localhost:8090/v1/charges?order="+orderId+"&amount="+amount).openConnection();
      c.setRequestMethod("POST"); c.setConnectTimeout(2000); c.setReadTimeout(SOCKET_TIMEOUT_MS);
      try (InputStream in = c.getInputStream()) { return new String(in.readAllBytes()); }
    } catch (SocketTimeoutException e) {
      throw new ConnectionTimeoutException("SocketTimeout: " + SOCKET_TIMEOUT_MS + "ms", e);
    } catch (IOException e) {
      throw new RuntimeException("Stripe gateway error", e);
    }
  }
}
EOF

cat > $SRC/PaymentController.java <<'EOF'
package com.shopnow;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.*;
@RestController @ConditionalOnProperty(name="shopnow.role", havingValue="payment")
public class PaymentController {
  private final StripeGatewayConnector stripe;
  public PaymentController(StripeGatewayConnector s){ this.stripe = s; }
  @PostMapping("/payments/authorize")
  public String authorize(@RequestParam String orderId, @RequestParam String amount) {
    return stripe.authorize(orderId, amount);   // exception -> HTTP 500 (failed request in Dynatrace)
  }
}
EOF

cat > $SRC/StripeMockController.java <<'EOF'
package com.shopnow;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.web.bind.annotation.*;
import java.util.concurrent.ThreadLocalRandom;
@RestController @ConditionalOnProperty(name="shopnow.role", havingValue="stripe")
public class StripeMockController {
  static volatile int faultPercent = 0;          // % of calls that hang 8s (> 5s timeout)
  @PostMapping("/v1/charges")
  public String charge(@RequestParam String order) throws InterruptedException {
    if (ThreadLocalRandom.current().nextInt(100) < faultPercent) Thread.sleep(8000);
    return "{\"status\":\"succeeded\",\"order\":\"" + order + "\"}";
  }
  @GetMapping("/admin/fault")
  public String fault(@RequestParam int percent){ faultPercent = percent; return "faultPercent=" + percent; }
}
EOF

echo ">>> [4/5] Building (first build downloads deps, ~2-4 min)"
cd $APP/src && mvn -q -DskipTests package
cp target/shopnow-1.0.jar $APP/shopnow.jar

echo ">>> [5/5] systemd services"
mk() { # name role port
cat > /etc/systemd/system/$1.service <<EOF
[Unit]
Description=ShopNow $1
After=network.target
[Service]
Environment=DT_CLUSTER_ID=$1
Environment=DT_TAGS=app=ShopNow
ExecStart=/usr/bin/java -Dspring.application.name=$1 -Dshopnow.role=$2 -Dserver.port=$3 -jar $APP/shopnow.jar
Restart=always
[Install]
WantedBy=multi-user.target
EOF
}
mk CheckoutService checkout 8081
mk PaymentService  payment  8082
mk stripe-mock     stripe   8090

cat > /etc/systemd/system/shopnow-load.service <<'EOF'
[Unit]
Description=ShopNow traffic generator
After=CheckoutService.service
[Service]
ExecStart=/bin/bash -c 'i=0; while true; do i=$((i+1)); curl -s -o /dev/null -X POST "http://localhost:8081/checkout?orderId=ORD-$i&amount=49.99" & sleep 0.5; done'
Restart=always
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo
echo "DONE. Next: install OneAgent (see runbook step B), then run:  sudo bash shopnow_ctl.sh start"
