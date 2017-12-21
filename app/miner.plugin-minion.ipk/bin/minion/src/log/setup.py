# -*- coding: utf-8 -*-
import errno
import sys
import logging
import logging.handlers
from logging.handlers import WatchedFileHandler,TimedRotatingFileHandler
import os
from os.path import dirname


__LOGFILE_CONFIGURED = False


LOG_LEVELS = {
    'all': logging.NOTSET,
    'debug': logging.DEBUG,
    'error': logging.ERROR,
    'critical': logging.CRITICAL,
    'info': logging.INFO,
    'warning': logging.WARNING,
}


def is_logfile_configured():
    return __LOGFILE_CONFIGURED

def set_logger_level(logger_name, log_level='error'):
    '''
    Tweak a specific logger's logging level
    '''
    logging.getLogger(logger_name).setLevel(
        LOG_LEVELS.get(log_level.lower(), logging.ERROR)
    )

def mkdir_p(path):
    '''
    mkdir -p
    http://stackoverflow.com/a/600612/127816
    '''
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise
        

def setup_logfile_logger(log_path, log_level='info', log_format=None,
                         date_format=None):
    
    if is_logfile_configured():
        logging.getLogger(__name__).warn('Logfile logging already configured')
        return
    
    if log_path is None:
        logging.getLogger(__name__).warn(
            'log_path setting is set to `None`. Nothing else to do'
        )
        return
    
    try:
        mkdir_p(dirname(log_path))
    except OSError as e:
        logging.getLogger(__name__).warning("failed to create log path error: {0}".format(str(e)))
        sys.exit(1)
                        
    if log_level is None:
        log_level = 'warning'

    level = LOG_LEVELS.get(log_level.lower(), logging.ERROR)
    root_logger = logging.getLogger()
    
    try:
        # Logfile logging is UTF-8 on purpose.
        #handler = WatchedFileHandler(log_path, mode='a', encoding='utf-8', delay=0)
        handler = TimedRotatingFileHandler(log_path, when="H", encoding='utf-8',  backupCount=5)
    except (IOError, OSError):
        logging.getLogger(__name__).warning(
            'Failed to open log file, do you have permission to write to '
            '{0}?'.format(log_path)
        )
        return
    
    handler.setLevel(level)

    if not log_format:
        log_format = '%(asctime)s [%(name)-15s][%(process)d]: %(message)s'
    if not date_format:
        date_format = '%Y-%m-%d %H:%M:%S'

    formatter = logging.Formatter(log_format, datefmt=date_format)

    handler.setFormatter(formatter)
    root_logger.addHandler(handler)

    global __LOGFILE_CONFIGURED
    __LOGFILE_CONFIGURED = True
