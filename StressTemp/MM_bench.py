import torch
import time
import os
import numpy as np
device = torch.device("cuda")


N = int(os.environ["MATRIX_SIZE"])
PREC = os.environ["PREC"]

if PREC == "BF16": prec = torch.bfloat16
elif PREC == "FP16": prec = torch.float16
elif PREC == "FP32": prec = torch.float32
elif PREC == "FP64": prec = torch.float64
elif PREC == "C128": prec = torch.complex128
else:
    raise Exception(f"The precision given {PREC} is not defined. Allowed values are : BF16, FP16, FP32, FP64 and C128")

A = torch.randn((N, N), device=device, dtype=prec)
B = torch.randn((N, N), device=device, dtype=prec)


times_array = []

D = int(os.environ["DATA_SIZE"])
print(D)

for i in range(D):
    torch.cuda.synchronize()

    t1 = time.time()

    C = torch.matmul(A, B)
    torch.cuda.synchronize()

    t2 = time.time()

    times_array.append([t1, t2-t1])

savefile = os.environ["SAVE_FILE"]
np.savez(f'{savefile}/MM_times_{N}_{PREC}', np.array(times_array))

