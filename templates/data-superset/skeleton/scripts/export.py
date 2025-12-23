#!/usr/bin/env python3
"""
Export Superset assets to JSON files.
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


def export_dashboards(session, base_url, dashboard_slug):
    """Export dashboard and related assets."""
    print(f"Exporting dashboard: {dashboard_slug}")
    
    # Get dashboard
    response = session.get(f"{base_url}/api/v1/dashboard/?q=(filters:!((col:slug,opr:eq,value:{dashboard_slug})))")
    if response.status_code != 200:
        print(f"  Error fetching dashboard: {response.text}")
        return
    
    dashboards = response.json().get('result', [])
    if not dashboards:
        print(f"  Dashboard not found: {dashboard_slug}")
        return
    
    dashboard = dashboards[0]
    dashboard_id = dashboard['id']
    
    # Export dashboard
    response = session.get(f"{base_url}/api/v1/dashboard/export/?q=[{dashboard_id}]")
    if response.status_code == 200:
        Path('dashboards').mkdir(exist_ok=True)
        with open(f"dashboards/{dashboard_slug}.json", 'w') as f:
            json.dump(response.json(), f, indent=2)
        print(f"  Exported to dashboards/{dashboard_slug}.json")
    else:
        print(f"  Error exporting: {response.text}")


def main():
    dashboard_slug = os.getenv('DASHBOARD_SLUG', '${{ values.name }}')
    
    print("Connecting to Superset...")
    session, base_url = get_superset_session()
    
    print("\nExporting assets...")
    export_dashboards(session, base_url, dashboard_slug)
    
    print("\nExport complete!")


if __name__ == '__main__':
    main()
