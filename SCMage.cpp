#include <string>
#include "mage.h"
#include "SC_PlugIn.h"
#include <pthread.h>

static InterfaceTable *ft;

struct SCMage : public Unit {
    MAGE::Mage* mage;
    uint32 bufnum;
    SndBuf *buf;
    float freqValue;
    float freqAction;
    pthread_t thread;
};

static void SCMage_allocFailed(SCMage* unit);
static void SCMage_next(SCMage* unit, int inNumSamples);
static void SCMage_Ctor(SCMage* unit);
static void* SCMage_genThread(void* argv);
static bool SCMage_pushLabelsFromSndBuf(World* world, SndBuf* buf, MAGE::Mage* mage);

void SCMage_allocFailed(SCMage* unit) {
    SETCALC(ft->fClearUnitOutputs);
    ClearUnitOutputs(unit, 1);
    if (unit->mWorld->mVerbosity > -2) {
        Print("Failed to allocate memory for SCMage ugen.\n");
    }
}

bool SCMage_pushLabelsFromSndBuf(World* world, SndBuf* buf, MAGE::Mage* mage) {
    float* bufData = buf->data;
    int bufFrames = buf->frames;
    int bufChannels = buf->channels;
    int bufSamples = buf->samples;

    // Create an intermediate buffer for converting the first channel of the sound buf into chars.
    char* stringBuf = (char*)RTAlloc(world, sizeof(char) * MAGE::maxStrLen);

    // If memory allocation failed, bail out.
    if (!stringBuf) {
        return false;
    }

    // This is the current length of the intermediate string.
    int charIndex = 0;
    for (int bufIndex = 0; bufIndex < bufSamples; bufIndex += bufChannels) {
        char character = bufData[bufIndex];
        // Allow premature null-termination (optional).
        if (character == '\0') {
            break;
        }
        // Copy the character into the intermediate buffer.
        if (charIndex < MAGE::maxStrLen) {
            stringBuf[charIndex] = character;
        }
        // Newlines push the label and flush the intermediate buffer.
        if (character == '\n') {
            std::string labelString(stringBuf, charIndex);
            MAGE::Label label(labelString);
            mage->pushLabel(label);
            charIndex = 0;
        } else {
            if (charIndex < MAGE::maxStrLen) {
                charIndex += 1;
            }
        }
    }
    RTFree(world, stringBuf);
    return true;
}

void SCMage_Ctor(SCMage* unit) {
    void* mage_memory = RTAlloc(unit->mWorld, sizeof(MAGE::Mage));
    if (!mage_memory) {
        SCMage_allocFailed(unit);
        return;
    }

    unit->mage = new(mage_memory) MAGE::Mage();

    int bufnum = IN0(0);
    

    // If the buffer number is negative, ignore it.
    // Later on there will be other ways to push labels through OSC commands.
    if (bufnum >= 0) {
        SndBuf* buf;
        World* world = unit->mWorld;
        if (bufnum >= world->mNumSndBufs) {
            int localBufNum = bufnum - world->mNumSndBufs;
            Graph *parent = unit->mParent;
            if (localBufNum <= parent->localBufNum) {
                buf = parent->mLocalSndBufs + localBufNum;
            } else {
                bufnum = 0;
                buf = world->mSndBufs + bufnum;
            }
        } else {
            buf = world->mSndBufs + bufnum;
        }
        bool allocSucceeded = SCMage_pushLabelsFromSndBuf(world, buf, unit->mage);
        if (!allocSucceeded) {
            SCMage_allocFailed(unit);
            return;
        }
    }

    unit->freqValue = 0.0f;
    unit->freqAction = MAGE::noaction;

  
    pthread_create(&(unit->thread), NULL, SCMage_genThread, (void*)unit);

    SETCALC(SCMage_next);
    OUT0(0) = 0.0f;
}

void SCMage_next(SCMage* unit, int inNumSamples) {
    float freqValue = IN0(1);
    float freqAction = IN0(2);
    float timeScale = IN0(3);
    float alpha = IN0(4);
    float *out = OUT(0);

    unit->freqValue = freqValue;
    unit->freqAction = freqAction;

    if (unit->mage->ready()) {
        unit->mage->setSpeed(timeScale * MAGE::defaultFrameRate, MAGE::overwrite);
        unit->mage->setAlpha(alpha);
    }
    for (int i = 0; i < inNumSamples; i++) {
        unit->mage->updateSamples();
        out[i] = unit->mage->popSamples();
    }
}

// TOD: complete the path to CMU_ARCTIC voices - U
const std::string prefix = "../data/cmu-arctic/voices/";

void SCMage_addVoice(SCMage* unit, std::string voiceName) {
    int mage_argc = 47;
    const std::string mage_argv_strings[mage_argc] = {
        "-s", "48000", // TODO: match server's sample rate
        "-p", "240",
        "-a", "0.55",
        "-td", prefix + voiceName + "/tree-dur.inf",
        "-tm", prefix + voiceName + "/tree-mgc.inf",
        "-tf", prefix + voiceName + "/tree-lf0.inf",
        "-tl", prefix + voiceName + "/tree-lpf.inf",
        "-md", prefix + voiceName + "/dur.pdf",
        "-mm", prefix + voiceName + "/mgc.pdf",
        "-mf", prefix + voiceName + "/lf0.pdf",
        "-ml", prefix + voiceName + "/lpf.pdf",
        "-dm", prefix + voiceName + "/mgc.win1",
        "-dm", prefix + voiceName + "/mgc.win2",
        "-dm", prefix + voiceName + "/mgc.win3",
        "-df", prefix + voiceName + "/lf0.win1",
        "-df", prefix + voiceName + "/lf0.win2",
        "-df", prefix + voiceName + "/lf0.win3",
        "-dl", prefix + voiceName + "/lpf.win1",
        "-em", prefix + voiceName + "/tree-gv-mgc.inf",
        "-ef", prefix + voiceName + "/tree-gv-lf0.inf",
        "-cm", prefix + voiceName + "/gv-mgc.pdf",
        "-cf", prefix + voiceName + "/gv-lf0.pdf",
        "-k", prefix + voiceName + "/gv-switch.inf",
        // This argument (referred to as labfn in the MAGE source) is not used.
        // But if I leave it out, I get a segfault. (?????)
        ""
    };

    // Convert from std::strings to C-style strings as required by addEngine
    char** mage_argv = new char*[MAGE::maxNumOfArguments];
    for (int i = 0; i < mage_argc; i++) {
        mage_argv[i] = new char[MAGE::maxStrLen];
        strcpy(mage_argv[i], mage_argv_strings[i].c_str());
    }

    unit->mage->addEngine(voiceName, mage_argc, mage_argv);
}


void* SCMage_genThread(void* argv) {

    SCMage* unit = (SCMage*)argv;

    
    // voice selector added
    int voiceNum = IN0(5);
    std::string voiceName = "slt";
    if (voiceNum == 0){voiceName = "awb";}
    if (voiceNum == 1){voiceName = "bdl";}
    if (voiceNum == 2){voiceName = "clb";}
    if (voiceNum == 3){voiceName = "jmk";}
    if (voiceNum == 4){voiceName = "rms";}
    if (voiceNum == 5){voiceName = "slt";}

    SCMage_addVoice(unit, voiceName);
    //SCMage_addVoice(unit, "slt");
    

    while (1) {
        pthread_testcancel();
        if (unit->mage->ready()) {
            unit->mage->run();
            unit->mage->setPitch(unit->freqValue, unit->freqAction);
            usleep(100);
        } else {
            usleep(100);
        }
    }
    return NULL;
}

void SCMage_Dtor(SCMage* unit) {
    pthread_cancel(unit->thread);
    pthread_join(unit->thread, NULL);
    unit->mage->~Mage();
    RTFree(unit->mWorld, unit->mage);
}



PluginLoad(SCMageUGens) {
    ft = inTable;
    DefineDtorUnit(SCMage);
}
