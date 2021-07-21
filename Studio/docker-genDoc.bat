@echo on
cd C:\Users\%username%\Documents\Hackolade
docker-compose run --rm hackoladeStudioCLI hackolade genDoc --model=/home/hackolade/Documents/data/model.json --format=html --doc=/home/hackolade/Documents/data/doc.html
pause
