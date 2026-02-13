"""Structured logging configuration."""
import logging
import json
from pythonjsonlogger import jsonlogger
from app.config import settings


def setup_logging():
    """Configure structured JSON logging."""
    logger = logging.getLogger()
    logger.setLevel(settings.log_level)

    # Remove default handlers
    for handler in logger.handlers[:]:
        logger.removeHandler(handler)

    # JSON handler for structured logging
    json_handler = logging.StreamHandler()
    json_formatter = jsonlogger.JsonFormatter(
        "%(timestamp)s %(level)s %(name)s %(message)s",
        timestamp=True
    )
    json_handler.setFormatter(json_formatter)
    logger.addHandler(json_handler)

    return logger


def get_logger(name: str) -> logging.Logger:
    """Get a logger instance with the given name."""
    return logging.getLogger(name)
