SCMage : UGen {
    classvar <>scMagePath;

    *initClass {
        //scMagePath = PathName(this.filenameSymbol.asString).pathOnly;
		//TODO: edit path for your system
        scMagePath = PathName.new("/home/user/code/SCMage");
    }

    *ar { |bufnum, freqValue = 0.0, freqMode = -1, timeScale = 1.0, alpha = 0.55, voiceNum = 0|
		^this.multiNew('audio', bufnum, freqValue, freqMode, timeScale, alpha, voiceNum);
    }

    *labelize { |text, action|

        var text2utt, dumpfeats, convertFeaturesToLabels, removeDurationsFromLabels, cleanUp;
        var prefix;
        var labelFileString;

        //TODO: edit path for your system
        prefix = "/home/user/tmp/" ++ 8.collect({ "0123456789abcdef".choose }).join("");
        File.use(prefix ++ ".txt", "w", { |textFile|
            textFile.write(text);
			prefix.postln;
        });


        // Step 1: Convert the text into a Festival utterance file.
        text2utt = { |action|
            [
				"/usr/bin/text2utt",
                prefix ++ ".txt",
                ">", prefix ++ ".utt"
            ].join(" ").unixCmd(action, false);
        };


        // Step 2: Convert the utterance file into a text file of space-separated values.
        dumpfeats = { |action|
            [
				"/usr/bin/dumpfeats",
				"-eval", "/home/user/code/SCMage/extra_feats.scm",
                "-relation", "Segment",
				"-feats", "/home/user/code/SCMage/label.feats",
                "-output", prefix ++ ".extracted_features.txt",
                prefix ++ ".utt"
            ].join(" ").unixCmd(action, false);
        };


        // Step 3: Convert the space-separated values into a label file with durations.
        convertFeaturesToLabels = { |action|
            [
                "gawk",
				"-f", "/home/user/code/SCMage/label-full.awk",
                prefix ++ ".extracted_features.txt",
                ">",
                prefix ++ ".with_durations.lab"
            ].join(" ").unixCmd(action, false);
        };


        // Step 4: Remove the excess durations from the label files.
        removeDurationsFromLabels = { |action|
            [
                "gawk",
                "-F\" \"",
                "'{print $3}'",
                prefix ++ ".with_durations.lab",
                ">",
                prefix ++ ".lab"
            ].join(" ").unixCmd(action, false);
        };


        // sorry, SC doesn't have promises
        text2utt.({
            dumpfeats.({
                convertFeaturesToLabels.({
                    removeDurationsFromLabels.({
                        File.use(prefix ++ ".lab", "r", { |labelFile|
                            labelFileString = labelFile.readAllString;
                        });
                        action.value(labelFileString);
                    });
                });
            });
        });

    }

    *labelBuf { |text, action|
        this.labelize(text, { |labelString|
            var buf;
            buf = Buffer.loadCollection(Server.default, labelString.ascii);
            action.value(buf);
        });
    }
}
