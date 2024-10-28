#!/bin/bash

# 从命令行获取输入参数
round=$1         # 第一个参数：迭代次数
threads=$2       # 第二个参数：线程数
read=$3          # 第三个参数：read 文件
read_type=$4     # 第四个参数：read 的类型 (clr, hifi, ont)
input=$5         # 第五个参数：组装好的 contig 文件

# 定义映射选项
declare -A mapping_option=(["clr"]="map-pb" ["hifi"]="asm20" ["ont"]="map-ont")

# 迭代运行 nextpolish2 的主要循环
for ((i=1; i<=${round};i++)); do
    # 运行 minimap2 进行比对，并生成 BAM 文件
    minimap2 -ax ${mapping_option[$read_type]} -t ${threads} ${input} ${read} | samtools sort - -m 2g --threads ${threads} -o lgs.sort.bam;
    
    # 索引 BAM 文件
    samtools index lgs.sort.bam;
    
    # 生成 BAM 文件的清单文件
    ls `pwd`/lgs.sort.bam > lgs.sort.bam.fofn;
    
    # 运行 nextpolish2.py 进行基因组抛光
    python nextpolish2.py -g ${input} -l lgs.sort.bam.fofn -r ${read_type} -p ${threads} -sp -o genome.nextpolish.fa;
    
    # 如果当前不是最后一轮迭代，更新输入文件
    if ((i != ${round})); then
        mv genome.nextpolish.fa genome.nextpolishtmp.fa;
        input=genome.nextpolishtmp.fa;
    fi;
done;

# 输出最终抛光后的基因组文件
echo "最终抛光的基因组文件为: genome.nextpolish.fa"