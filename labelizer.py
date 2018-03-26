'''
Crude TTS frontend

MIT License
'''
import re


def link_consecutive(the_list):
    for index in range(0, len(the_list) - 1):
        the_list[index].next = the_list[index + 1]
        the_list[index + 1].previous = the_list[index]
    return the_list


def forward_position(element, the_list):
    return the_list.index(element) + 1


def backward_position(element, the_list):
    return len(the_list) - the_list.index(element)

# these are inefficient, i don't care


def count_before(the_list, target, predicate):
    count = 0
    for element in the_list:
        if element == target:
            return count
        if predicate(element):
            count += 1


def count_after(the_list, target, predicate):
    return count_before(the_list[::-1], target, predicate)


def distance_from_previous(the_list, target, predicate):
    distance = 0
    for element in the_list:
        distance += 1
        if element == target:
            return distance
        if predicate(element):
            distance = 0


def distance_to_next(the_list, target, predicate):
    return distance_from_previous(the_list[::-1], target, predicate)


class Phoneme:

    def __init__(self, parent, name):
        self.parent = parent
        self.name = name
        self.previous = None
        self.next = None

    def safe_previous(self):
        if self.previous is None:
            return sentinel_phoneme
        return self.previous

    def safe_next(self):
        if self.next is None:
            return sentinel_phoneme
        return self.next

    def forward_position_in_syllable(self):
        return forward_position(self, self.parent.phonemes)

    def backward_position_in_syllable(self):
        return backward_position(self, self.parent.phonemes)

sentinel_phoneme = Phoneme(None, "x")


class Syllable:

    def __init__(self, parent, phonemes, stress, vowel_name):
        self.parent = parent
        self.stressed = 1 if stress == 1 else 0
        self.accented = 1 if stress == 2 else 0
        self.vowel_name = vowel_name
        self.phonemes = [Phoneme(self, phoneme) for phoneme in phonemes]
        self.previous = None
        self.next = None

    def number_of_phonemes(self):
        return len(self.phonemes)

    def safe_previous(self):
        if self.previous is None:
            return sentinel_syllable
        return self.previous

    def safe_next(self):
        if self.next is None:
            return sentinel_syllable
        return self.next

    def phrase_syllables(self):
        return list(self.parent.parent.syllables())

    def forward_position_in_word(self):
        return forward_position(self, self.parent.syllables)

    def backward_position_in_word(self):
        return backward_position(self, self.parent.syllables)

    def forward_position_in_phrase(self):
        return forward_position(self, self.phrase_syllables())

    def backward_position_in_phrase(self):
        return backward_position(self, self.phrase_syllables())

    # this is repetitive, i don't care

    def stressed_syllables_before_this_in_phrase(self):
        return count_before(self.phrase_syllables(), self, lambda syllable: syllable.stressed)

    def stressed_syllables_after_this_in_phrase(self):
        return count_after(self.phrase_syllables(), self, lambda syllable: syllable.stressed)

    def accented_syllables_before_this_in_phrase(self):
        return count_before(self.phrase_syllables(), self, lambda syllable: syllable.accented)

    def accented_syllables_after_this_in_phrase(self):
        return count_after(self.phrase_syllables(), self, lambda syllable: syllable.accented)

    # yuck

    def distance_from_previous_stressed_syllable(self):
        return distance_from_previous(list(self.parent.parent.parent.syllables()), self, lambda syllable: syllable.stressed)

    def distance_to_next_stressed_syllable(self):
        return distance_to_next(list(self.parent.parent.parent.syllables()), self, lambda syllable: syllable.stressed)

    def distance_from_previous_accented_syllable(self):
        return distance_from_previous(list(self.parent.parent.parent.syllables()), self, lambda syllable: syllable.accented)

    def distance_to_next_accented_syllable(self):
        return distance_to_next(list(self.parent.parent.parent.syllables()), self, lambda syllable: syllable.accented)

sentinel_syllable = Syllable(None, [], 0, "x")


class Word:

    def __init__(self, parent, syllables):
        self.parent = parent
        self.syllables = [Syllable(self, *syllable) for syllable in syllables]
        self.previous = None
        self.next = None

    def number_of_syllables(self):
        return len(self.syllables)


class Phrase:

    def __init__(self, parent, words):
        self.parent = parent
        self.words = [Word(self, word) for word in words]
        self.previous = None
        self.next = None

    def number_of_words(self):
        return len(self.words)

    def number_of_syllables(self):
        return sum([word.number_of_syllables() for word in self.words])

    def syllables(self):
        for word in self.words:
            for syllable in word.syllables:
                yield syllable


label_template = re.sub(r"\s+", "", """
{p1}^{p2}-{p3}+{p4}={p5}@{p6}_{p7}
/A:{a1}_{a2}_{a3}
/B:{b1}-{b2}-{b3}@{b4}-{b5}&{b6}-{b7}#{b8}-{b9}${b10}-{b11}!{b12}-{b13};{b14}-{b15}|{b16}
/C:{c1}+{c2}+{c3}
/J:{j1}+{j2}-{j3}
""")


class Utterance:

    def __init__(self, phrases):
        self.phrases = [Phrase(self, phrase) for phrase in phrases]
        link_consecutive(list(self.phonemes()))
        link_consecutive(list(self.syllables()))
        link_consecutive(list(self.words()))

    def number_of_phrases(self):
        return len(self.phrases)

    def number_of_words(self):
        return sum([phrase.number_of_words() for phrase in self.phrases])

    def number_of_syllables(self):
        return sum([phrase.number_of_syllables() for phrase in self.phrases])

    def phonemes(self):
        for phrase in self.phrases:
            for word in phrase.words:
                for syllable in word.syllables:
                    for phoneme in syllable.phonemes:
                        yield phoneme

    def syllables(self):
        for phrase in self.phrases:
            for word in phrase.words:
                for syllable in word.syllables:
                    yield syllable

    def words(self):
        for phrase in self.phrases:
            for word in phrase.words:
                yield word

    def as_labels(self):
        output = []
        for phoneme in self.phonemes():
            syllable = phoneme.parent
            word = syllable.parent
            phrase = word.parent
            output.append(label_template.format(
                p1=phoneme.safe_previous().safe_previous().name,
                p2=phoneme.safe_previous().name,
                p3=phoneme.name,
                p4=phoneme.safe_next().name,
                p5=phoneme.safe_next().safe_next().name,
                p6=phoneme.forward_position_in_syllable(),
                p7=phoneme.backward_position_in_syllable(),
                a1=syllable.safe_previous().stressed,
                a2=syllable.safe_previous().accented,
                a3=syllable.safe_previous().number_of_phonemes(),
                b1=syllable.stressed,
                b2=syllable.accented,
                b3=syllable.number_of_phonemes(),
                b4=syllable.forward_position_in_word(),
                b5=syllable.backward_position_in_word(),
                b6=syllable.forward_position_in_phrase(),
                b7=syllable.backward_position_in_phrase(),
                b8=syllable.stressed_syllables_before_this_in_phrase(),
                b9=syllable.stressed_syllables_after_this_in_phrase(),
                b10=syllable.accented_syllables_before_this_in_phrase(),
                b11=syllable.accented_syllables_after_this_in_phrase(),
                b12=syllable.distance_from_previous_stressed_syllable(),
                b13=syllable.distance_to_next_stressed_syllable(),
                b14=syllable.distance_from_previous_accented_syllable(),
                b15=syllable.distance_to_next_accented_syllable(),
                b16=syllable.vowel_name,
                c1=syllable.safe_next().stressed,
                c2=syllable.safe_next().accented,
                c3=syllable.safe_next().number_of_phonemes(),
                j1=self.number_of_syllables(),
                j2=self.number_of_words(),
                j3=self.number_of_phrases()
                ))
        return output


def extract_stress_and_vowel_name(syllable):
    stress = 0
    output_syllable = []
    for phoneme in syllable:
        if phoneme[-1].isdigit():
            stress = int(phoneme[-1])
            phoneme = phoneme[:-1]
            vowel_name = phoneme
        output_syllable.append(phoneme)
    return (output_syllable, stress, vowel_name)


def clump_syllables(phonemes):
    vowel_positions = []
    for index, phoneme in enumerate(phonemes):
        if phoneme[-1].isdigit():
            vowel_positions.append(index)
    syllable_positions = [0] + [position + 1 for position in vowel_positions] + [len(phonemes)]
    syllables = [phonemes[syllable_positions[i]:syllable_positions[i + 1]] for i in range(len(syllable_positions) - 1)]
    ending_consonants = syllables.pop()
    syllables[-1] += ending_consonants

    return [extract_stress_and_vowel_name(syllable) for syllable in syllables]



cmudict = {}

with open("/home/nathan/git/SCMage/cmudict-0.7b", "r", encoding="windows-1252") as cmudict_file:
    for line in cmudict_file:
        if not line.startswith(";;;"):
            line = line[:-1]
            word, phonemes = line.split("  ")
            word = word.lower()
            phonemes = phonemes.split(" ")
            phonemes = [phoneme.lower() for phoneme in phonemes]
            syllables = clump_syllables(phonemes)
            cmudict[word] = syllables

#sentence = "What to say is more important than how to say it"
#sentence = "It has been raining on and off since the day before yesterday"
sentence = "I went all the way to see her only to find her away from home"

sentence = sentence.split(" ")
sentence = [word.lower() for word in sentence]
phrases = [[cmudict[word] for word in sentence]]
utterance = Utterance(phrases)
labels = utterance.as_labels()
for label in labels:
    print("unit->mage->pushLabel(MAGE::Label(\"" + label + "\"));")
