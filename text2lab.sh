#!/bin/sh

TEXT2LAB=~/git/SCMage/tools/text2lab
FESTIVAL=~/git/SCMage/festival/programs/festival
TEXT2UTT=$FESTIVAL/examples/text2utt
DUMPFEATS=$FESTIVAL/examples/dumpfeats
base=`basename $1 .txt`
$TEXT2UTT $1 > /tmp/utterance.utt
$DUMPFEATS -eval $TEXT2LAB/extra_feats.scm -relation Segment -feats $TEXT2LAB/label.feats -output /tmp/extracted_features.txt /tmp/utterance.utt
gawk -f $TEXT2LAB/label-full.awk /tmp/extracted_features.txt > /tmp/with_durations.lab
# gawk -f $TEXT2LAB/label-mono.awk tmp > $base-mono.lab
gawk -F" " '{print $3}' /tmp/with_durations.lab > $base.lab
