# simplified_spanish_grammar

This is the code developed as an empirical proof of the ideas defended in my PhD Thesis 'SSG: Simplified Spanish Grammar. An HPSG grammar of Spanish with a reduced computational cost'. You can find it [here](http://eprints.ucm.es/25069/). And a summary [here](http://journal.sepln.org/sepln/ojs/ojs/index.php/pln/article/view/5100). 

## Perl Dependencies
* DBI
* DBD::mysql
* XML::Simple
* XML::Path
* Graphviz

## Installation
* Tested in Ubuntu 16.04
* Install mysql server
* Install Perl dependencies
* Run:
...perl CreateLexicon.pl
...perl LoadNewGrammar.pl 
...Enter Mysql user and password; and ssg as grammar
...perl LoadNewGrammar.pl
...Enter Mysql user and password; and nssg as grammar

## Testing

* Run ssg:
...perl ParseSentences.pl
...Enter Mysql user and password; ssg as grammar and 1 as scrambling
...Enter one of the sentences of ./TestSuite.txt
...See the result in ./TREES

* Run nssg:
...perl ParseSentences.pl
...Enter Mysql user and password; nssg as grammar and 0 as scrambling
...Enter one of the sentences of ./TestSuite.txt
...See the result in ./TREES
