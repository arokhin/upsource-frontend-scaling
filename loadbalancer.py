#!/usr/bin/env python
import hashlib
import os
import signal
import urllib
import json
import subprocess
import sys
import datetime
from shutil import copy2

from jinja2 import Environment, FileSystemLoader

#print 'Arguments list: ', str(sys.argv)
url = sys.argv[1]
template_path, template_name = os.path.split(sys.argv[2])
output_file = sys.argv[3]
is_debug = os.getenv('UPSOURCE_PROXY_DEBUG') == "true"
script_path = os.getenv('HAPROXY_SCRIPTS_LOCATION')


def init_config():
    f = open(script_path + '/conf/haproxy/initial.json', 'r')
    data = f.read()
    f.close()
    fill_template(data, output_file)



def check_updates():
    if (is_debug):
        print datetime.datetime.now(), "Checking updates..."
    try:
        response = urllib.urlopen(url)
        data = json.loads(response.read())
    except:
        print "Error occurred while communicating with monitoring [" + url + "]. Perhaps it hasn't been started yet."
        print "Keep existing configuration."
        sys.exit(0)

    newmd5 = hashlib.md5()
    newmd5.update(str(data))
    newmd5 = newmd5.hexdigest()

    # find md5 hash of old configuration
    if os.path.isfile('/tmp/haproxy/md5-store'):
        with open('/tmp/haproxy/md5-store', 'rw+') as md5_store:
            oldmd5=md5_store.read()
    else:
        if not os.path.exists('/tmp/haproxy/'):
            os.makedirs('/tmp/haproxy/')
        oldmd5=''

    if newmd5 == oldmd5:
        if (is_debug):
            print "No changes detected."
        sys.exit(0)
    else:
        print "New data: "  + str(data)

    return data


def fill_template(data, dest):
    j2_env = Environment(loader=FileSystemLoader(template_path), trim_blocks=True)
    out = j2_env.get_template(template_name).render(data=data, env=os.environ)

    f = open(dest, 'w')
    f.write(out)
    f.close()

    print "Created the new config file:" + dest

    return


def save_md5(data):
    md5 = hashlib.md5()
    md5.update(str(data))
    md5 = md5.hexdigest()

    with open('/tmp/haproxy/md5-store', 'w+') as md5_store:
        md5_store.write(md5)
        md5_store.close()
    print "Saved md5 sum: " + md5

    return


def reload_server():
    # Check haproxy.cfg here
    child = subprocess.Popen('/usr/local/sbin/haproxy -c -C /tmp/haproxy -f haproxy.cfg', stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, shell=True)
    child.communicate()
    child.wait()
    rc=child.returncode

    if rc == 0:
        # Copy tested configuration to production and reload
        copy2('/tmp/haproxy/haproxy.cfg', output_file)
        haproxyWrapperPid = sys.argv[4]
        pid=int(open(haproxyWrapperPid).read())
        os.kill(pid,signal.SIGHUP)
        print "New configuration has been applied at " + output_file
    else:
        print "New configuration NOT applied. haproxy validation process exited with code " + str(rc)

    return


if __name__ == '__main__':
    data = check_updates()
    fill_template(data, '/tmp/haproxy/haproxy.cfg')
    save_md5(data)
    reload_server()
