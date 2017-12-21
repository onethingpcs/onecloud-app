# -*- coding: utf-8 -*-
'''
    author: lining
    email: lining3@xunlei.com


    docker-minion.log
    ~~~~~~~~

    This is where logging gets set up. Currently, the required imports
    are made to assure backwards compatibility.
'''

from log.setup import (
    LOG_LEVELS,
    setup_logfile_logger,
    set_logger_level,
)