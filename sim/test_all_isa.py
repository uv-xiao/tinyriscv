import os

def list_binfiles(path):
    files = []
    list_dir = os.walk(path)
    for maindir, subdir, all_file in list_dir:
        for filename in all_file:
            apath = os.path.join(maindir, filename)
            if apath.endswith('.bin'):
                files.append(apath)

    return files


files = list_binfiles('../tests/isa/generated')


anyfail = False

for file in files:
    #print(file)
    cmd = './sim_new_nowave.sh ' + file + ' inst.data'
    f = os.popen(cmd)
    r = f.read()
    f.close()
    if (r.find('TEST_PASS') != -1):
        print(file + '    PASS')
    else:
        print(file + '    !!!FAIL!!!')
        anyfail = True
        break

if (anyfail == False):
    print('Congratulation, All PASS...')
