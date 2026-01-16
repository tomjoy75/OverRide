#!/bin/python3
import  sys
import string

def find_offset(signal):
    try:
        raw = bytes.fromhex(signal)
    except ValueError:
        return -1
    eip = raw[::-1].decode(encoding="latin-1")
    pattern = generate_patterns(2000)
    return pattern.find(eip)


def generate_patterns(size):
    pattern = ''.join(
            f'{upper}{lower}{number}'
            for upper in string.ascii_uppercase
            for lower in string.ascii_lowercase
            for number in string.digits)
    nb_iter = size // len(pattern)
    offset = size % len(pattern)
    return (pattern * nb_iter + pattern[:offset])

if __name__=="__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--offset":
        offset = find_offset(sys.argv[2])
        print(f"Exact match at offset {offset}") if offset != -1 else print("Not a valid hex")
#        return sys.argv[2].find

    elif len(sys.argv) == 2:
        print(generate_patterns(int(sys.argv[1])))
    else :
        print("Please provide a size or a crash string")

