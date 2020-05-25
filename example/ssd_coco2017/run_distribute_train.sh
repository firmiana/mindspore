#!/bin/bash
# Copyright 2020 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

echo "================================================================================================================="
echo "Please run the scipt as: "
echo "sh run_distribute_train.sh DEVICE_NUM EPOCH_SIZE DATASET MINDSPORE_HCCL_CONFIG_PATH PRE_TRAINED PRE_TRAINED_EPOCH_SIZE"
echo "for example: sh run_distribute_train.sh 8 350 coco /data/hccl.json /opt/ssd-300.ckpt(optional) 200(optional)"
echo "It is better to use absolute path."
echo "The learning rate is 0.4 as default, if you want other lr, please change the value in this script."
echo "================================================================================================================="

if [ $# != 4 ] && [ $# != 6 ]
then
    echo "Usage: sh run_distribute_train.sh [DEVICE_NUM] [EPOCH_SIZE] [DATASET] \
[MINDSPORE_HCCL_CONFIG_PATH] [PRE_TRAINED](optional) [PRE_TRAINED_EPOCH_SIZE](optional)"
    exit 1
fi

# Before start distribute train, first create mindrecord files.
python train.py --only_create_dataset=1

echo "After running the scipt, the network runs in the background. The log will be generated in LOGx/log.txt"

export RANK_SIZE=$1
EPOCH_SIZE=$2
DATASET=$3
PRE_TRAINED=$5
PRE_TRAINED_EPOCH_SIZE=$6
export MINDSPORE_HCCL_CONFIG_PATH=$4


for((i=0;i<RANK_SIZE;i++))
do
    export DEVICE_ID=$i
    rm -rf LOG$i
    mkdir ./LOG$i
    cp  *.py ./LOG$i
    cd ./LOG$i || exit
    export RANK_ID=$i
    echo "start training for rank $i, device $DEVICE_ID"
    env > env.log
    if [ $# == 4 ]
    then
        python ../train.py  \
        --distribute=1  \
        --lr=0.4 \
        --dataset=$DATASET \
        --device_num=$RANK_SIZE  \
        --device_id=$DEVICE_ID  \
        --epoch_size=$EPOCH_SIZE > log.txt 2>&1 &
    fi

    if [ $# == 6 ]
    then
        python ../train.py  \
        --distribute=1  \
        --lr=0.4 \
        --dataset=$DATASET \
        --device_num=$RANK_SIZE  \
        --device_id=$DEVICE_ID  \
        --pre_trained=$PRE_TRAINED \
        --pre_trained_epoch_size=$PRE_TRAINED_EPOCH_SIZE \
        --epoch_size=$EPOCH_SIZE > log.txt 2>&1 &
    fi

    cd ../
done
