import unittest
import size
from size import *

class TestSize(unittest.TestCase):
    
    def test_human_size(self):
        self.assertEqual(32, from_human_size("32B"))
        self.assertEqual(32000, from_human_size("32Kb"))
        self.assertEqual(32*TB, from_human_size("32Tb"))
        self.assertRaises(TypeError, from_human_size, "ttttt")
        
    def test_mem_size(self):
        self.assertEqual(34, mem_in_bytes("34b"))
        self.assertEqual(32*KiB, mem_in_bytes("32Kb"))
        self.assertEqual(32*GiB, mem_in_bytes("32gb"))
        self.assertRaises(TypeError, mem_in_bytes, "-1")
        self.assertRaises(TypeError, mem_in_bytes, "100 kb")
        
    def test_calc_size(self):
        self.assertEqual(34, calc_size("34 B"))
        self.assertEqual(34*KB, calc_size("34 KB"))
        self.assertEqual(3.4*KiB, calc_size("3.4 KiB"))
        self.assertEqual(34*KiB, calc_size("34 KiB"))
        

if __name__ == "__main__":
    unittest.main()