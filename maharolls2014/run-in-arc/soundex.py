#! /usr/bin/env python
# -*- coding: utf-8 -*-
# 
# Copyright 2008-2009 Santhosh Thottingal <santhosh.thottingal@gmail.com>
# http://thottingal.in
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# If you find any bugs or have any suggestions email: santhosh.thottingal@gmail.com
# URL: http://www.smc.org.in

import sys
import os

sys.stdin = os.fdopen(sys.stdin.fileno(),"r",1,"utf-8")

# import codecs
# sys.stdout = codecs.getwriter('utf8')(sys.stdout)
# sys.stdin = codecs.getreader('utf8')(sys.stdin) 

from  charmap import *

def soundexCode(char):
	index=0
	lang= language(char)
	try:
		if lang == "en_US":
			return charmap["soundex_en"][charmap[lang].index(char)]
		else:
			return charmap["soundex"][charmap[lang].index(char)]	
	except:
		'''In case of any exception- Mostly because of character not found in charmap'''
		return 0		
	return 0		

def soundex(name, len=8):
	sndx =''
	fc = ''
	# translate alpha chars in name to soundex digits
	for c in name.lower():
		if not fc: fc = c   # remember first letter
		d = str(soundexCode(c))
		if d== '0' : continue
		# duplicate consecutive soundex digits are skipped
		if not sndx or (d != sndx[-1]): 
			sndx += d
	
	
	# replace first digit with first alpha character
	sndx = fc + sndx[1:]
	
		
	# return soundex code padded to len characters
	return (sndx + (len * '0'))[:len]

def compare(string1, string2):
	#do a quick check
	if string1 == string2 : #Exact Match
		return 0 
	soundex1=	soundex(string1)
	soundex2=	soundex(string2)
	if soundex1 == soundex2	: #Both sounds alike
		return 1
	#Check whether the first letters are phonetically same from different languages
	if soundexCode( string1[0]) == soundexCode(string2[0]):
		if soundex1[1:] == soundex2[1:]	: #Both sounds alike
			return 2
	#Strings doesnot match	
	return -1	
			   
if __name__ == '__main__':
	# f = codecs.open("soundextmp","r","utf8")
	# s = f.read()
	# f.close()
        f = open("fifo","wb",0) 
        while 1:
            s = sys.stdin.readline()
            f.write(soundex(s).encode("utf8"))
          
