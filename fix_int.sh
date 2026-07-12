#!/bin/bash
sed -i '' 's/Int(Double(\([^)]*\)) \* mutationMultiplier)/(\1 * mutationMultiplier).safeInt()/g' "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/GameManager/GameManager+Inventory.swift"
sed -i '' 's/Int(Double(\([^)]*\)) \* mutationMultiplier)/(\1 * mutationMultiplier).safeInt()/g' "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/GameManager/GameManager+Economy.swift"
sed -i '' 's/Int(Double(totalYield) \* mutationMultiplier)/(Double(totalYield) * mutationMultiplier).safeInt()/g' "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/GameManager/GameManager+Inventory.swift"
sed -i '' 's/Int(Double(totalRecycleValue) \* retention)/(Double(totalRecycleValue) * retention).safeInt()/g' "/Users/dorian/Downloads/jeu tycoon /jeu tycoon/jeu tycoon/Sources/GameManager/GameManager+Inventory.swift"
