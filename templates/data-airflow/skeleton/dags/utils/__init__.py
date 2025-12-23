"""Utility functions for ${{ values.name }} DAG."""

from datetime import datetime
from typing import Any, Dict, List, Optional


def validate_data(data: Dict[str, Any], required_fields: List[str]) -> bool:
    """
    Validate that data contains all required fields.
    
    Args:
        data: Dictionary to validate
        required_fields: List of required field names
        
    Returns:
        True if all required fields present, False otherwise
    """
    return all(field in data for field in required_fields)


def format_date(date: datetime, format_str: str = '%Y-%m-%d') -> str:
    """
    Format a datetime object to string.
    
    Args:
        date: Datetime object to format
        format_str: strftime format string
        
    Returns:
        Formatted date string
    """
    return date.strftime(format_str)


def chunk_list(lst: List[Any], chunk_size: int) -> List[List[Any]]:
    """
    Split a list into chunks of specified size.
    
    Args:
        lst: List to chunk
        chunk_size: Size of each chunk
        
    Returns:
        List of chunks
    """
    return [lst[i:i + chunk_size] for i in range(0, len(lst), chunk_size)]


def get_connection_string(
    host: str,
    port: int,
    database: str,
    user: str,
    password: str,
    driver: str = 'postgresql'
) -> str:
    """
    Build a database connection string.
    
    Args:
        host: Database host
        port: Database port
        database: Database name
        user: Database user
        password: Database password
        driver: Database driver
        
    Returns:
        Connection string
    """
    return f"{driver}://{user}:{password}@{host}:{port}/{database}"
