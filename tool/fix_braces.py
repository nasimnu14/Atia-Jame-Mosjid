#!/usr/bin/env python3
"""`dart format` splits `if (x) return y;` onto two lines, which the analyzer's
curly_braces_in_flow_control_structures lint then flags. This wraps those
single statements in braces. Usage: python3 tool/fix_braces.py lib test
"""
import os
import re
import sys

PAT = re.compile(
    r'^(?P<i>[ ]*)(?P<head>(?:\} else )?(?:if|for|while) \([^\n]*\))\n(?P=i)  (?P<body>[^\n{][^\n]*;)\n',
    re.M)

total = 0
for root in sys.argv[1:]:
    for dp, _, fs in os.walk(root):
        for f in fs:
            if not f.endswith('.dart') or f.endswith('.g.dart'):
                continue
            path = os.path.join(dp, f)
            s = open(path, encoding='utf-8').read()
            n = 0

            def rep(m):
                global total
                nonlocal_n[0] += 1
                return f"{m['i']}{m['head']} {{\n{m['i']}  {m['body']}\n{m['i']}}}\n"

            nonlocal_n = [0]
            s2 = PAT.sub(rep, s)
            if nonlocal_n[0]:
                open(path, 'w', encoding='utf-8').write(s2)
                total += nonlocal_n[0]
print('wrapped', total)
