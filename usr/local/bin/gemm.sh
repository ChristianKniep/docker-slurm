#!/bin/bash
KVAL=${1-16384}
SLEEP=${2-250}
JOBID=${SLURM_JOBID}
NLIST=${SLURM_NODELIST}
START_TIME=$(date +%s)
CMD="/usr/local/bin/gemm_block_mpi_${SLEEP}ms -K ${KVAL}"
send_event.py --server graphite \
              -t "job${JOBID},start,k${KVAL},${SLEEP}ms" \
              -d "NODES: ${NLIST} CMD: ${CMD}" \
              "Job ${JOBID} starts. K:${KVAL}"
echo "####################################################"
echo "################ JOBRUN ############################"
echo "####################################################"
mpirun -q ${CMD}
echo "####################################################"
echo "################ \JOBRUN ############################"
echo "####################################################"
WTIME=$(echo "$(date +%s) - ${START_TIME}"|bc)
send_event.py --server graphite \
              -t "job${JOBID},end,k${KVAL},${SLEEP}ms" \
              -d "Some more info" \
              "Job ${JOBID} ends K:${KVAL}; wall:${WTIME}"
