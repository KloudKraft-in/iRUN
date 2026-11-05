Save these files here before you run `lab check` (names are exact):

  dev-validation.txt     console output of the Development-mode run that CRASHED at startup (before your fix)
  program.diff           your Program.cs diff (DI registration + Kestrel limits)
  requests.txt           terminal log showing HTTP 200 for /health/ready and HTTP 413 for the 2 MB POST
  publish-listing.txt    directory listing of the self-contained publish folder
