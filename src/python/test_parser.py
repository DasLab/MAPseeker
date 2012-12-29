#!/usr/bin/python
from argparse import ArgumentParser

parser =  ArgumentParser()

parser.add_argument("-o", "--my-option", dest="my_option",nargs='*')
parser.add_argument("-b", "--blah", dest="blah",action="store_true")
( args ) = parser.parse_args()

print "my_option ==> ",  args.my_option
print "blah ==> ", args.blah
