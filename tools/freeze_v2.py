"""Create or verify the local source/protocol lock for the revised evaluation."""
from pathlib import Path
import argparse,hashlib,json,datetime
ROOT=Path(__file__).resolve().parents[1]
LOCK=ROOT/'results/v2/lock.json'
def files():
    f=list(ROOT.glob('*.m'))+list((ROOT/'src').glob('*.m'))+list((ROOT/'tests').glob('*.m'))
    f+=list((ROOT/'tuning').glob('*.m'))+list((ROOT/'validation').glob('*.m'))+list((ROOT/'results/v2').glob('tuning_*.csv'))
    f+=[ROOT/'docs/V2_PROTOCOL.md',ROOT/'tools/analyze_v2.py',Path(__file__)]
    return sorted(set(p for p in f if p.name!='lock.json'))
def verify():
    record=json.loads(LOCK.read_text(encoding='utf-8'))
    for name,digest in record['sources'].items():
        if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest:
            raise RuntimeError(f'Frozen source changed: {name}')
    return record
def freeze():
    if LOCK.exists():
        verify();print('Existing lock verified; not overwritten.');return
    fl=files()
    record={'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'development_seeds':[11,23,47],'validation_seeds':[901,902],
            'evaluation_seeds':list(range(201,221)),'conditions':14,'methods':9,'planned_trials':14*9*20,
            'bootstrap_resamples':10000,'bootstrap_analysis_seed':20261107,
            'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in fl}}
    LOCK.write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    print(f'Locked {len(fl)} files before the held-out evaluation.')
if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--freeze',action='store_true');a=ap.parse_args()
    if a.freeze:freeze()
    else:r=verify();print(f'Verified {len(r["sources"])} frozen hashes.')
