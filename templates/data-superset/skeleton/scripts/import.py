#!/usr/bin/env python3
"""
Import Superset assets from JSON files.
"""

import json
import os
import requests
from pathlib import Path


def get_superset_session():
    """Create authenticated session with Superset."""
    base_url = os.getenv('SUPERSET_URL', 'http://localhost:8088')
    username = os.getenv('SUPERSET_USERNAME', 'admin')
    password = os.getenv('SUPERSET_PASSWORD', 'admin')
    
    session = requests.Session()
    
    # Get CSRF token
    response = session.get(f"{base_url}/api/v1/security/csrf_token/")
    csrf_token = response.json()['result']
    session.headers['X-CSRFToken'] = csrf_token
    
    # Login
    login_payload = {
        'username': username,
        'password': password,
        'provider': 'db'
    }
    session.post(f"{base_url}/api/v1/security/login", json=login_payload)
    
    return session, base_url


def import_databases(session, base_url):
    """Import database connections."""
    db_dir = Path('databases')
    if not db_dir.exists():
        return
    
    for db_file in db_dir.glob('*.json'):
        with open(db_file) as f:
            config = json.load(f)
        
        print(f"Importing database: {config['database_name']}")
        response = session.post(f"{base_url}/api/v1/database/", json=config)
        if response.status_code in [200, 201]:
            print(f"  Success: {db_file.name}")
        else:
            print(f"  Error: {response.text}")


def import_datasets(session, base_url):
    """Import datasets/tables."""
    dataset_dir = Path('datasets')
    if not dataset_dir.exists():
        return
    
    for ds_file in dataset_dir.glob('*.json'):
        with open(ds_file) as f:
            config = json.load(f)
        
        print(f"Importing dataset: {config['table_name']}")
        response = session.post(f"{base_url}/api/v1/dataset/", json=config)
        if response.status_code in [200, 201]:
            print(f"  Success: {ds_file.name}")
        else:
            print(f"  Error: {response.text}")


def import_charts(session, base_url):
    """Import chart configurations."""
    chart_dir = Path('charts')
    if not chart_dir.exists():
        return
    
    for chart_file in chart_dir.glob('*.json'):
        with open(chart_file) as f:
            config = json.load(f)
        
        print(f"Importing chart: {config['slice_name']}")
        response = session.post(f"{base_url}/api/v1/chart/", json=config)
        if response.status_code in [200, 201]:
            print(f"  Success: {chart_file.name}")
        else:
            print(f"  Error: {response.text}")


def import_dashboards(session, base_url):
    """Import dashboard configurations."""
    dashboard_dir = Path('dashboards')
    if not dashboard_dir.exists():
        return
    
    for dash_file in dashboard_dir.glob('*.json'):
        with open(dash_file) as f:
            config = json.load(f)
        
        print(f"Importing dashboard: {config['dashboard_title']}")
        response = session.post(f"{base_url}/api/v1/dashboard/", json=config)
        if response.status_code in [200, 201]:
            print(f"  Success: {dash_file.name}")
        else:
            print(f"  Error: {response.text}")


def main():
    print("Connecting to Superset...")
    session, base_url = get_superset_session()
    
    print("\nImporting assets...")
    import_databases(session, base_url)
    import_datasets(session, base_url)
    import_charts(session, base_url)
    import_dashboards(session, base_url)
    
    print("\nImport complete!")


if __name__ == '__main__':
    main()
