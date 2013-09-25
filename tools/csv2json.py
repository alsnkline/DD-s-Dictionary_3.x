#!/usr/bin/env python

import csv
import json
import sys
import traceback

#: which columns are always lists
list_cols={"collections", "dm", "homophones", "tags", "pronunciations"}
#: which columns might be lists if space is present
list_maybe={"word"}

def process_token(v):
    v=v.strip()
    if ":" not in v:
        return v
    return dict([[v.strip() for v in v.split(":", 1)]])

def convert(infile, outfile):
    incsv=csv.DictReader(infile)
    res=[]
    lastgoodline=None
    for lineno, line in enumerate(incsv):
        try:
            row=line.copy()
            for k,v in row.items():
                if not v:
                    del row[k]
                    continue
                if k in list_cols or (k in list_maybe and len(v.split())>1):
                    row[k]=[process_token(v) for v in v.split()]
                elif k in list_maybe:
                    row[k]=process_token(v)

            res.append(row)
            lastgoodline=line
        except:
            traceback.print_exc()
            print >> sys.stderr, "While processing row #", lineno+2
            print >> sys.stderr, "Last good line\n"+json.dumps(lastgoodline, sort_keys=True, indent=4)
            sys.exit(1)

    print >> outfile, json.dumps({"words": res}, sort_keys=True, indent=4)

if __name__=='__main__':
    import argparse

    p=argparse.ArgumentParser(description="Converts the word list from CSV into json")
    p.add_argument("--input", default=sys.stdin, type=argparse.FileType('r'), help="Input file [stdin]")
    p.add_argument("--output", default=sys.stdout, type=argparse.FileType('w'), help="Output file [stdout]")

    options=p.parse_args()

    if options.input.isatty():
        p.error("Input is a terminal.  Pipe files or provide filenames")

    convert(options.input, options.output)
