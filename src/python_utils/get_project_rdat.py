import argparse
import pdb

parser = argparse.ArgumentParser()

parser.add_argument('input', type=argparse.FileType('r'))
parser.add_argument('projectname', type=str)
parser.add_argument('--m2', default=False, action='store_true')
parser.add_argument('--offset', type=int, default=0)

args = parser.parse_args()
if args.m2:
    obligatory_tags = ['VERSION', 'COMMENT', 'ANNOTATION\t']
else:
    obligatory_tags = ['VERSION', 'SEQPOS', 'SEQUENCE', 'COMMENT', 'ANNOTATION\t']
def get_seq(line):
    for anno in line.strip().split('\t'):
        if 'sequence' in anno:
            return anno.replace('sequence:','')
                 
line = args.input.readline()
curridx = 1
idxmap = {}
oblglines = []
reactlines = []
annolines = []
reactidces = []
offsetindices = {}
finished = False
read_prev = False
args.projectname = args.projectname.replace('\\t', '\t')
visited = []
while line:
    addstr = ''
    for tag in obligatory_tags:
        if tag in line:
            oblglines.append(line)
            if tag == 'VERSION':
                oblglines.append('NAME\t%s\n' % args.projectname)
    if 'ANNOTATION_DATA' in line and args.projectname in line and 'signal_to_noise:weak' not in line and not finished:
        name = line.strip().split('\t')[1].strip()
        if name not in visited:
            idx = int(line.strip().replace('ANNOTATION_DATA:', '').split('\t')[0])
            reactidces.append(str(idx))
            idxmap[str(idx)] = curridx
            if args.m2:
                if curridx == 0:
                    wtseq = get_seq(line)
                    seqpos = ['%s%s' % (s, i+1+args.offset) for i, s in enumerate(wtseq)]
                    oblglines.append('SEQUENCE\t%s\n' % wtseq)
                else:
                    seq = get_seq(line)
                    for i in xrange(len(seq)):
                        if seq[i] != wtseq[i]:
                            #addstr += '\tmutation:%s%s%s' % (wtseq[i], i+1+args.offset, seq[i])
                            break
            curridx += 1
            annoline = 'ANNOTATION_DATA:%d\t' % idxmap[str(idx)]
            annoline += line[line.find('\t'):].strip() + addstr + '\n'
            annolines.append(annoline)
            visited.append(name)
    if 'REACTIVITY' in line:
        finished = True
        if 'ERROR' in line:
            tag = 'REACTIVITY_ERROR'
        else:
            tag = 'REACTIVITY'
        idx = line.strip().replace('%s:' % tag, '').split('\t')[0].strip()
        if idx in reactidces:
            reacts = line.strip().replace('%s:%s' % (tag, idx), '').strip().split('\t')
            if args.m2:
                reactlines.append('%s:%s\t%s\n' % (tag, idxmap[idx], '\t'.join([reacts[i] for i in range(len(seqpos))])))
            else:
                reactlines.append('%s:%s\t%s\n' % (tag, idxmap[idx], '\t'.join(reacts)))
    if args.m2:
        if 'SEQPOS' in line:
            inseqpos = [x[1:] for x in line.replace('SEQPOS\t', '').strip().split('\t')]
            seqpos = [s for i, s in enumerate(seqpos[:-28]) if i < len(inseqpos)]
            oblglines.append('SEQPOS\t%s\n' % '\t'.join(seqpos))

    if 'OFFSET' in line:
        oblglines.append('OFFSET\t%s\n' % args.offset)
    line = args.input.readline()

def writelines(lines):
    for line in lines:
        print line.strip() + '\n'

writelines(oblglines)
writelines(annolines)
writelines(reactlines)
