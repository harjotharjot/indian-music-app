import hashlib
import json
import unittest
import numpy as np
from benchmark import detect, metrics
from signals import ROOT, SR, tone

class AudioTests(unittest.TestCase):
    def test_download_integrity(self):
        entries=json.loads((ROOT/'samples.json').read_text())
        self.assertTrue({'harmonium','tanpura','tabla','voice'} <= {e['role'] for e in entries})
        for entry in entries:
            self.assertEqual(hashlib.sha256((ROOT/'assets'/entry['file']).read_bytes()).hexdigest(),entry['sha256'])

    def test_yin_clean_reference(self):
        # An acceptance test of a reused library, not our own estimator.
        for hz in [65.4064,110,220,440,880]:
            for cents in [-37,17]:
                f=hz*2**(cents/1200)
                times,values=detect(tone(f)[0],'aubio_yin')
                keep=(times>.3)&(times<.8)
                result=metrics(values[keep],np.full(sum(keep),f))
                with self.subTest(hz=hz,cents=cents):
                    self.assertGreater(result['coverage_pct'],99)
                    self.assertLess(result['median_abs_cents'],3)
                    self.assertEqual(result['octave_error_pct'],0)

    def test_yin_silence(self):
        _,values=detect(np.zeros(SR,dtype=np.float32),'aubio_yin')
        self.assertFalse(np.isfinite(values).any())

    def test_octave_metric_does_not_hide_errors(self):
        result=metrics(np.array([220.,440.,110.,np.nan]),np.full(4,220.))
        self.assertEqual(result['coverage_pct'],75)
        self.assertAlmostEqual(result['octave_error_pct'],200/3)
        self.assertEqual(metrics(np.array([np.nan]),np.array([220.]))['coverage_pct'],0)

if __name__=='__main__':
    unittest.main()
