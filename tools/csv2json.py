#!/usr/bin/env python

import csv
import json
import sys
import traceback

#: which columns are always lists
list_cols={"collections", "dm", "homophones", "tags", "pronunciations"}
#: which columns might be lists if space is present
list_maybe={"word"}
#: which columns are for the google spreadsheet only ie not to be put into the output.
list_ignore={"Special", "Recording Needed", "Recording notes"}

def process_token(v):
    v=v.strip()
    return v

def process_dict(v, list=False):
    d={}
    for i in v.split():
        l=i.split(":", 1)
        if list:
            d[l.pop().strip()] = [l.pop().strip()]
        else:
            d[l.pop().strip()] = l.pop().strip()
    return d

def convert(infile, outfile):
    incsv=csv.DictReader(infile)
    res=[]
    lastgoodline=None
    for lineno, line in enumerate(incsv):
        try:
            row=line.copy()
            if row["collections"] == "EXCLUDE":
                continue
            for k,v in row.items():
                if not v or (k in list_ignore):
                    del row[k]
                    continue
                if ":" in v:
                    if "[" in v:
                        #find and process the embedded list separately then reassemble
                        lvwz=v[v.find("[")+1:v.find("]")]
                        lvwz=[process_token(lvwz) for lvwz in lvwz.split()]

                        v=v[:v.find("[")]+"lvwz"+v[v.find("]")+1:]
                        d=process_dict(v, k in list_cols)
                        for m,n in d.items():
                            if n[0] == "lvwz":
                                d[m]=lvwz
                        row[k]=d
                    else:
                        row[k]=process_dict(v, k in list_cols)
                elif k in list_cols or (k in list_maybe and len(v.split())>1):
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
