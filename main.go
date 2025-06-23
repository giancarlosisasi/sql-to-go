package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

type ColumnInfo struct {
	Name         string
	GoType       string
	IsNullable   bool
	IsPrimaryKey bool
}

func main() {
	var dbUrl = flag.String("db", "", "Postgresql url connection.")
	var outputDir = flag.String("output", "./models", "Output directory for generated go files")
	var packageName = flag.String("package", "models", "Package name for generated Go files")
	var outputMode = flag.String("mode", "combined", "Output mode: 'combined' (single file), 'separate' (one file per table), or 'both")
	var help = flag.Bool("help", false, "Show help information")

	flag.Parse()

	// Show help if requested or if no database URL provided
	if *help || *dbUrl == "" {
		fmt.Println("Database Schema to Go Struct Generator")
		fmt.Println("=====================================")
		fmt.Println()
		fmt.Println("Usage:")
		fmt.Printf("  %s -db <database_url> [flags]\n", os.Args[0])
		fmt.Println()
		flag.PrintDefaults()
		fmt.Println()
		fmt.Println("Output modes:")
		fmt.Println("  combined  - Generate all structs in a single models.go file (default)")
		fmt.Println("  separate  - Generate one file per table (users.go, posts.go, etc.)")
		fmt.Println("  both      - Generate both combined and separate files")
		fmt.Println()
		fmt.Println("Examples:")
		fmt.Printf("  %s -db \"postgres://user:password@localhost:5432/blogapp?sslmode=disable\"\n", os.Args[0])
		fmt.Printf("  %s -db \"...\" -mode separate -output ./internal/models\n", os.Args[0])
		fmt.Printf("  %s -db \"...\" -mode both -package entities\n", os.Args[0])

		if *dbUrl == "" {
			os.Exit(1)
		}

		return
	}

	fmt.Printf("✅ Received database URL: %s\n", *dbUrl)

	ctx := context.Background()
	dbpool, err := pgxpool.New(ctx, *dbUrl)
	if err != nil {
		fmt.Printf("❌ Failed to open database connection: %v\n", err)
		os.Exit(1)
	}
	defer dbpool.Close()

	err = dbpool.Ping(ctx)
	if err != nil {
		fmt.Printf("❌ Failed to ping database: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("✅ Successfully connected to PostgreSQL!")

	fmt.Println("📋 Fetching tables from database...")

	query := `
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema = 'public'
		AND table_type = 'BASE TABLE'
		ORDER BY table_name
	`

	rows, err := dbpool.Query(ctx, query)
	if err != nil {
		fmt.Printf("❌ Failed to query tables: %v\n", err)
		os.Exit(1)
	}
	defer rows.Close()

	var tables []string

	for rows.Next() {
		var tableName string
		err := rows.Scan(&tableName)
		if err != nil {
			fmt.Printf("❌ Failed to scan table name: %v\n", err)
			os.Exit(1)
		}
		tables = append(tables, tableName)
	}

	// Check for any errors during iteration
	if rows.Err() != nil {
		fmt.Printf("❌ Error during row iteration: %v\n", err)
		os.Exit(1)
	}

	// Display results
	if len(tables) == 0 {
		fmt.Println("⚠️  No tables found in the public schema")
		return
	}

	// ================== Analyze all tables and transform them to go structs ================
	fmt.Printf("✅ Found %d table(s):\n", len(tables))
	for i, table := range tables {
		fmt.Printf("   %d.%s\n", i+1, table)
	}

	fmt.Println("\n🏗️  Generating Go structs for all tables...")
	fmt.Println(strings.Repeat("=", 60))

	// Create output directory if it doesn't exist
	// err = os.MkdirAll(*outputDir, 0755)
	// if err != nil {
	// 	fmt.Printf("❌ Failed to create output directory: %v\n", err)
	// 	os.Exit(1)
	// }
	outputPath := *outputDir
	if outputPath == "" {
		outputPath = "models"
	}
	outputPath = filepath.Clean(outputPath)

	if strings.HasPrefix(outputPath, "."+string(filepath.Separator)) {
		outputPath = outputPath[2:]
	} else if strings.HasPrefix(outputPath, "./") {
		outputPath = strings.Replace(outputPath, "./", "", 1)
	}

	absOutputDir, err := filepath.Abs(outputPath)
	if err != nil {
		fmt.Printf("❌ Failed to resolve output path '%s': %v\n", outputPath, err)
		os.Exit(1)
	}
	fmt.Printf("📁 Creating output directory: %s\n", absOutputDir)

	err = os.MkdirAll(absOutputDir, 0755)
	if err != nil {
		fmt.Printf("❌ Failed to create output directory '%s': %v\n", absOutputDir, err)
		fmt.Printf("💡 Try using an absolute path or ensure you have write permissions\n")
		os.Exit(1)
	}
	fmt.Printf("✅ Output directory ready: %s\n", absOutputDir)

	allStructs := make([]string, 0, len(tables))
	generatedFiles := make([]string, 0)

	for _, tableName := range tables {
		// fmt.Printf("\n📋 Table: %s\n", tableName)
		// fmt.Println(strings.Repeat("-", len(tableName)+8))

		columns, err := getTableColumns(ctx, dbpool, tableName)
		if err != nil {
			fmt.Printf("❌ Failed to get columns for table %s: %v\n", tableName, err)
			continue
		}

		if len(columns) > 0 {
			structCode := generateStruct(tableName, columns)
			allStructs = append(allStructs, structCode)

			if *outputMode == "separate" || *outputMode == "both" {
				fileContent := generateGoFile(*packageName, tableName, structCode)
				fileName := fmt.Sprintf("%s.go", strings.ToLower(tableName))
				filePath := filepath.Join(*outputDir, fileName)

				err := writeToFile(filePath, fileContent)
				if err != nil {
					fmt.Printf("❌ Failed to write file %s: %v\n", fileName, err)
					continue
				}

				generatedFiles = append(generatedFiles, fileName)
				fmt.Printf("✅ Generated: %s\n", filePath)
			}

		}
	}

	// generated combined file if requested
	if (*outputMode == "combined" || *outputMode == "both") && len(allStructs) > 0 {
		combinedContent := generateCombinedFile(*packageName, allStructs)
		combinedPath := filepath.Join(*outputDir, "models.go")

		err := writeToFile(combinedPath, combinedContent)
		if err != nil {
			fmt.Printf("❌ Failed to write combined file: %v\n", err)
		} else {
			fmt.Printf("✅ Generated combined file: %s\n", combinedPath)
			generatedFiles = append(generatedFiles, "models.go")
		}
	}

	// Summary
	fmt.Println(strings.Repeat("=", 60))
	fmt.Printf("🎉 Successfully generated %d Go struct(s)!\n", len(allStructs))
	fmt.Printf("📁 Output directory: %s\n", absOutputDir)
	fmt.Printf("📦 Package name: %s\n", *packageName)
	fmt.Printf("🔧 Output mode: %s\n", *outputMode)

	if len(generatedFiles) > 0 {
		fmt.Println("\n📝 Generated files:")
		for _, file := range generatedFiles {
			fmt.Printf("  - %s\n", file)
		}
	}
}
