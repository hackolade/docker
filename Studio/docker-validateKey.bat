@echo on
cd C:\Users\%username%\Documents\Hackolade
docker-compose run --rm hackoladeStudioCLI hackolade validatekey --key=<your-concurrent-license-key> --identifier=<a-unique-license-user-identifier>
pause
