#!/usr/bin/env bash
# Poll dunst notification history via D-Bus

busctl --user call org.freedesktop.Notifications \
    /org/freedesktop/Notifications \
    org.dunstproject.cmd0 NotificationListHistory 2>/dev/null | \
python3 -c "
import sys, re, json

raw = sys.stdin.read().strip()
if raw.startswith('aa{sv} 0') or not raw:
    print('[]')
    sys.exit(0)

# Remove prefix 'aa{sv} N '
raw = re.sub(r'^aa\{sv\} \d+ ', '', raw)

# Parse dbus-send style output: count \"key\" type value \"key2\" type2 value2 ...
# Each dict starts with a count (number), then key-value pairs
# Types: s=string, i=int32, x=int64, b=boolean

notifs = []
pos = 0
length = len(raw)

while pos < length:
    # Skip whitespace
    while pos < length and raw[pos] in ' \n\t':
        pos += 1
    if pos >= length:
        break
    
    # Read dict entry count
    if not raw[pos].isdigit():
        # Try to skip forward
        pos += 1
        continue
    
    count_str = ''
    while pos < length and raw[pos].isdigit():
        count_str += raw[pos]
        pos += 1
    
    if not count_str:
        break
    
    entry = {}
    
    # Parse key-value pairs for this dict
    while pos < length:
        while pos < length and raw[pos] in ' \n\t':
            pos += 1
        
        if pos >= length:
            break
        
        # Check if we hit the next dict count
        if raw[pos].isdigit():
            # Peek ahead - is this a new dict count or part of a value?
            peek = pos
            while peek < length and raw[peek].isdigit():
                peek += 1
            if peek < length and raw[peek] in ' \n\t':
                # This is a dict count, stop this entry
                break
        
        # Read key (quoted string)
        if raw[pos] != '\"':
            pos += 1
            continue
        pos += 1  # skip opening quote
        key = ''
        while pos < length and raw[pos] != '\"':
            if raw[pos] == '\\\\' and pos+1 < length:
                key += raw[pos+1]
                pos += 2
            else:
                key += raw[pos]
                pos += 1
        if pos < length:
            pos += 1  # skip closing quote
        
        # Skip whitespace
        while pos < length and raw[pos] in ' \n\t':
            pos += 1
        
        # Read type
        if pos >= length:
            break
        dtype = raw[pos]
        pos += 1
        
        # Skip whitespace
        while pos < length and raw[pos] in ' \n\t':
            pos += 1
        
        # Read value based on type
        if dtype == 's':
            # String value in quotes
            if pos < length and raw[pos] == '\"':
                pos += 1
                val = ''
                while pos < length and raw[pos] != '\"':
                    if raw[pos] == '\\\\' and pos+1 < length:
                        if raw[pos+1] == '\"':
                            val += '\"'
                        elif raw[pos+1] == 'n':
                            val += '\n'
                        elif raw[pos+1] == '\\\\':
                            val += '\\\\'
                        else:
                            val += '\\\\' + raw[pos+1]
                        pos += 2
                    else:
                        val += raw[pos]
                        pos += 1
                if pos < length:
                    pos += 1  # skip closing quote
                entry[key] = val
            else:
                entry[key] = ''
        elif dtype in ('i', 'x'):
            # Integer value
            val = ''
            while pos < length and raw[pos] in '-0123456789':
                val += raw[pos]
                pos += 1
            entry[key] = int(val) if val else 0
        elif dtype == 'b':
            val = ''
            while pos < length and raw[pos] in 'truefalse':
                val += raw[pos]
                pos += 1
            entry[key] = val == 'true'
        else:
            # Unknown type, skip
            while pos < length and raw[pos] not in ' \n\t\"':
                pos += 1
    
    if entry:
        notifs.append(entry)

# Convert to widget format
result = []
for n in notifs:
    ts = n.get('timestamp', 0)
    if isinstance(ts, int) and ts > 10000000000:
        ts = ts / 1000.0  # microseconds to seconds
    elif isinstance(ts, int):
        ts = float(ts)
    
    result.append({
        'uid': str(n.get('id', '0')),
        'appName': n.get('appname', 'System'),
        'summary': n.get('summary', 'Notification'),
        'body': n.get('body', ''),
        'appIcon': n.get('icon_path', ''),
        'actionsJson': '[]',
        'timestamp': ts,
        'hasActions': False
    })

result.reverse()
print(json.dumps(result))
" 2>/dev/null || echo '[]'
