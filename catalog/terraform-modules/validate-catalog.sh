#!/bin/bash

echo "🔍 Validating Backstage Catalog Configuration"
echo "=============================================="
echo

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Track errors
ERRORS=0

# Validate YAML syntax
echo "📄 Validating YAML syntax..."
for file in catalog-info.yaml gcp-vpc.yaml aws-vpc.yaml azure-vnet.yaml all-components.yaml modules.yaml; do
    if [ -f "$file" ]; then
        if python3 -c "import yaml; yaml.safe_load_all(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $file"
        else
            echo -e "${RED}✗${NC} $file - YAML syntax error"
            ((ERRORS++))
        fi
    fi
done
echo

# Check techdocs-ref annotations
echo "📚 Checking techdocs-ref annotations..."
python3 << 'PYTHON_EOF'
import yaml
files = {
    'catalog-info.yaml': 'terraform-modules',
    'gcp-vpc.yaml': 'gcp-vpc',
    'aws-vpc.yaml': 'aws-vpc',
    'azure-vnet.yaml': 'azure-vnet'
}

all_good = True
for f, expected_name in files.items():
    with open(f, 'r') as file:
        docs = list(yaml.safe_load_all(file.read()))
        for doc in docs:
            if doc and doc.get('kind') == 'Component':
                name = doc.get('metadata', {}).get('name')
                annotations = doc.get('metadata', {}).get('annotations', {})
                techdocs = annotations.get('backstage.io/techdocs-ref')
                
                if name != expected_name:
                    print(f"  ✗ {f}: Expected name '{expected_name}', got '{name}'")
                    all_good = False
                elif not techdocs:
                    print(f"  ✗ {f}: Missing techdocs-ref annotation")
                    all_good = False
                else:
                    print(f"  ✓ {name}: techdocs-ref={techdocs}")

if all_good:
    print("\n✅ All components have correct techdocs-ref annotations")
PYTHON_EOF
echo

# Check for unique names
echo "🔑 Checking for unique component names..."
python3 << 'PYTHON_EOF'
import yaml

files = ['catalog-info.yaml', 'gcp-vpc.yaml', 'aws-vpc.yaml', 'azure-vnet.yaml']
names = []

try:
    for f in files:
        with open(f, 'r') as file:
            docs = list(yaml.safe_load_all(file.read()))
            for doc in docs:
                if doc and doc.get('kind') == 'Component':
                    name = doc.get('metadata', {}).get('name')
                    names.append(name)
    
    if len(names) == len(set(names)):
        print("  ✓ All component names are unique:")
        for name in names:
            print(f"    - {name}")
    else:
        print("  ✗ Duplicate names found!")
        for name in names:
            count = names.count(name)
            if count > 1:
                print(f"    - {name} (appears {count} times)")
except Exception as e:
    print(f"  ✗ Error checking names: {e}")
PYTHON_EOF
echo

# Summary
echo "=============================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Validation passed!${NC}"
    echo
    echo "Next steps:"
    echo "1. Import 'all-components.yaml' into Backstage"
    echo "2. Or register individual component YAML files"
    echo "3. Wait for catalog processing (30-60 seconds)"
    echo "4. Verify components appear at: http://localhost:3000/catalog"
else
    echo -e "${RED}❌ Validation failed with $ERRORS errors${NC}"
    exit 1
fi
