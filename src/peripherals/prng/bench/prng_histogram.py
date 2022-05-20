#!/usr/bin/env python
#
# Plot a histogram of the PRNG module output
#
# Copyright (c) 2022 Matt Liss
# BSD-3-Clause
#
import csv
import sys
import numpy as np
import matplotlib.pyplot as plt


class PrngTest(object):
    def __init__(self, prng_file='prng_tb.vvp.out', hist_file='prng_tb_histogram.png'):
        self.rand_filename = prng_file
        self.hist_filename = hist_file

        self.read_prng_output()

    def read_prng_output(self):
        self.data = []

        with open(self.rand_filename, newline='') as csvfile:
            reader = csv.reader(csvfile)
            for row in reader:
                try:
                    value = int(row[0], 16)
                except ValueError:
                    continue
                self.data.append(value)

    def autocorr(self):
        result = np.correlate(self.data, self.data, mode='full')
        self.data_autocorr = result[int(result.size/2):]

        plt.plot(self.data_autocorr)
        plt.show()

    def plot_hist(self, bins=100):
        plt.hist(self.data, bins, density=False)
        plt.xlabel('Random Value')
        plt.ylabel('Value Count')
        plt.title('Histogram of PRNG Random Values')
        plt.grid(True)
        plt.savefig(self.hist_filename)

    def plot(self):
        plt.plot(self.data)
        plt.show()


def main():
    test = PrngTest(sys.argv[1], sys.argv[2])
    test.plot_hist()
    #test.autocorr()


if __name__ == '__main__':
    main()
