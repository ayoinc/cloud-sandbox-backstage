#!/usr/bin/env python3
"""
Extract APIs and Resources from old catalog files into a single file.
"""

import re
from pathlib import Path

CATALOG_DIR = Path("/Users/ayodeleajayi/Workspace/backstage/catalog")

OLD_FILES = [
    "cloud-components.yaml",
    "data-components.yaml",
    "infrastructure-components.yaml",
    "observability-components.yaml",
    "testing-components.yaml",
    "awx-core.yaml",
    "awx-operator.yaml",
    "sample-components.yaml",
]

def extract_apis_and_resources():
    """Extract API and Resource entities from old files."""
    apis_and_resources = []
    
    for filename in OLD_FILES:
        filepath = CATALOG_DIR / filename
        if not filepath.exists():
            print(f"Skipping {filename} - not found")
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Split by YAML document separator
        documents = content.split('\n---\n')
        
        for doc in documents:
            doc = doc.strip()
            if not doc:
                continue
            
            # Check if this is an API or Resource
            if 'kind: API' in doc or 'kind: Resource' in doc:
                apis_and_resources.append(doc)
                # Extract name for logging
                name_match = re.search(r'name:\s*(\S+)', doc)
                kind_match = re.search(r'kind:\s*(\S+)', doc)
                if name_match and kind_match:
                    print(f"Extracted {kind_match.group(1)}: {name_match.group(1)} from {filename}")
    
    return apis_and_resources

def main():
    print("Extracting APIs and Resources from old catalog files...\n")
    
    entities = extract_apis_and_resources()
    
    if not entities:
        print("No APIs or Resources found!")
        return
    
    # Write to new file
    output_file = CATALOG_DIR / "apis-and-resources.yaml"
    
    header = """# =============================================================================
# APIs and Resources for Cloud Sandbox Backstage
# =============================================================================
# This file contains all API and Resource definitions.
# Component definitions have been moved to individual directories with TechDocs.
# =============================================================================

"""
    
    with open(output_file, 'w') as f:
        f.write(header)
        f.write('\n---\n'.join(entities))
    
    print(f"\nWrote {len(entities)} entities to {output_file}")
    
    # List files to be removed
    print("\nFiles that can be removed:")
    for filename in OLD_FILES:
        filepath = CATALOG_DIR / filename
        if filepath.exists():
            print(f"  - {filepath}")

if __name__ == "__main__":
    main()
