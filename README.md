httptrail
=========

httptrail is a simple logging proxy for debugging http servers. It writes all
requests and responses to stdout. Requests are prefixed with `> `, responses
with `< `, similar to the output of `curl -v`.


Installation
------------

    npm install -g httptrail


Usage
-----

    httptrail <upstream host> <proxy port>


Examples
--------

    httptrail 8000 8001

    httptrail https://github.com/ 8000
