#!/bin/bash

mkdir -p lib/{core/{constants,theme,utils,errors},data/{datasources/{local,remote},models,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens/calculator/widgets,widgets,routes}}

touch lib/main.dart
touch lib/core/constants/.gitkeep
touch lib/core/theme/.gitkeep
touch lib/core/utils/.gitkeep
touch lib/core/errors/.gitkeep

touch lib/data/datasources/local/.gitkeep
touch lib/data/datasources/remote/.gitkeep
touch lib/data/models/.gitkeep
touch lib/data/repositories/.gitkeep

touch lib/domain/entities/.gitkeep
touch lib/domain/repositories/.gitkeep
touch lib/domain/usecases/.gitkeep

touch lib/presentation/providers/.gitkeep
touch lib/presentation/screens/calculator/calculator_screen.dart
touch lib/presentation/screens/calculator/widgets/.gitkeep
touch lib/presentation/widgets/.gitkeep
touch lib/presentation/routes/.gitkeep

echo "✅ Flutter project structure created successfully!"
