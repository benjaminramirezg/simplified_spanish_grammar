-- MySQL dump 10.13  Distrib 5.5.29, for debian-linux-gnu (i686)
--
-- Host: localhost    Database: lexicon
-- ------------------------------------------------------
-- Server version	5.5.29-0ubuntu0.12.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `form`
--

DROP TABLE IF EXISTS `form`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `form` (
  `lemma` varchar(50) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `form` varchar(50) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `cat` varchar(50) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `rule` varchar(50) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `clitic` varchar(50) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `class` varchar(50) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  PRIMARY KEY (`form`,`lemma`,`cat`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `form`
--

LOCK TABLES `form` WRITE;
/*!40000 ALTER TABLE `form` DISABLE KEYS */;
INSERT INTO `form` VALUES ('a','a','prep','prep-constant-irule',NULL,NULL),('acordarse','acuerdas','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule','Esnsin'),('acordarse','acuerdo','verb','verb-1-sg-present-indicative-irule','verb-non-clitic-irule','Esnsin'),('admirar','admiraba','verb','verb-3-sg-imperfect-indicative-irule','verb-non-clitic-irule','Esnssn'),('admirar','admiras','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule','Esnssn'),('belleza','belleza','noun','noun-fem-sg-irule',NULL,'idea'),('billete','billetes','noun','noun-masc-pl-irule',NULL,'object'),('botones','botones','noun','noun-masc-sg-irule',NULL,'person'),('calcular','calcular','verb','verb-inf-irule','verb-non-clitic-irule','Annnsn'),('cien','cien','det','det-pl-irule',NULL,NULL),('comparar','comparado','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Rnsnsn'),('comprar','comprar','verb','verb-inf-irule','verb-non-clitic-irule','Annnsn'),('comprar','comprarla','verb','verb-inf-irule','verb-la-irule','Annnsn'),('comprar','comprarlo','verb','verb-inf-irule','verb-lo-irule','Annnsn'),('con','con','prep','prep-constant-irule',NULL,NULL),('confiar','confiar','verb','verb-inf-irule','verb-non-clitic-irule','Ennsin'),('confiar','confía','verb','verb-3-sg-present-indicative-irule','verb-non-clitic-irule','Ennsin'),('confiar','confías','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule','Ennsin'),('contratar','contratado','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Rnnnsn'),('convencer','convencido','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Rnnssn'),('cosa','cosas','noun','noun-fem-pl-irule',NULL,'object'),('dar','dado','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Rnnnss'),('de','de','prep','prep-constant-irule',NULL,NULL),('deber','debes','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule','Ennnsn'),('desentenderse','desentiende','verb','verb-3-sg-present-indicative-irule','verb-non-clitic-irule','Asnsin'),('decir','dice','verb','verb-3-sg-present-indicative-irule','verb-non-clitic-irule','Annnsn'),('decir','dicen','verb','verb-3-pl-present-indicative-irule','verb-non-clitic-irule','Annnsn'),('dos','dos','det','det-pl-irule',NULL,NULL),('el','el','det','det-masc-sg-irule',NULL,NULL),('él','ella','det','det-fem-sg-irule',NULL,NULL),('él','ellos','det','det-masc-pl-irule',NULL,NULL),('en','en','prep','prep-constant-irule',NULL,NULL),('encargado','encargado','noun','noun-masc-sg-irule',NULL,'person'),('encontrar','encontrado','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Rnnnsn'),('entrada','entrada','noun','noun-fem-sg-irule',NULL,'object'),('entrada','entradas','noun','noun-fem-pl-irule',NULL,'object'),('equipaje','equipaje','noun','noun-masc-sg-irule',NULL,'object'),('ese','eso','det','det-masc-sg-irule',NULL,NULL),('euro','euros','noun','noun-masc-pl-irule',NULL,'object'),('guía','guía','noun','noun-masc-sg-irule',NULL,'person'),('guía','guías','noun','noun-masc-pl-irule',NULL,'person'),('haber','ha','verb','verb-3-sg-present-indicative-irule','verb-non-clitic-irule',NULL),('habitación','habitación','noun','noun-fem-sg-irule',NULL,'location'),('haber','han','verb','verb-3-pl-present-indicative-irule','verb-non-clitic-irule',NULL),('haber','has','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule',NULL),('hasta','hasta','prep','prep-constant-irule',NULL,NULL),('hotel','hotel','noun','noun-masc-sg-irule',NULL,'person'),('el','la','det','det-fem-sg-irule',NULL,NULL),('el','las','det','det-fem-pl-irule',NULL,NULL),('el','los','det','det-masc-pl-irule',NULL,NULL),('nosotros','nosotros','det','det-1-pl-irule',NULL,NULL),('oficina','oficina','noun','noun-fem-sg-irule',NULL,'location'),('pagar','pagar','verb','verb-inf-irule','verb-non-clitic-irule','Annnsn'),('pagar','pagarlo','verb','verb-inf-irule','verb-lo-irule','Annnsn'),('perder','perdido','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Rnnnsn'),('poder','podemos','verb','verb-1-pl-present-indicative-irule','verb-non-clitic-irule','Ennnsn'),('precio','precio','noun','noun-masc-sg-irule',NULL,'idea'),('precio','precios','noun','noun-masc-pl-irule',NULL,'idea'),('poder','puedo','verb','verb-1-sg-present-indicative-irule','verb-non-clitic-irule','Ennnsn'),('que','que','comp','comp-constant-irule',NULL,NULL),('querer','queremos','verb','verb-1-pl-present-indicative-irule','verb-non-clitic-irule','Ennnsn'),('quién','quién','det','det-sg-irule',NULL,NULL),('qué','qué','det','det-sg-irule',NULL,NULL),('relacionarse','relacionar','verb','verb-inf-irule','verb-non-clitic-irule','Assnin'),('relacionarse','relacionas','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule','Assnin'),('resort','resort','noun','noun-masc-sg-irule',NULL,'location'),('saber','sabe','verb','verb-3-sg-present-indicative-irule','verb-non-clitic-irule','Ennssn'),('saber','sabes','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule','Ennssn'),('saber','sabido','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Ennssn'),('secar','secado','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Csnntn'),('si','si','comp','comp-constant-irule',NULL,NULL),('ser','sido','verb','verb-part-masc-sg-irule','verb-non-clitic-irule',NULL),('situación','situación','noun','noun-fem-sg-irule',NULL,'idea'),('su','su','det','det-sg-irule',NULL,NULL),('subir','suban','verb','verb-3-pl-present-subjuntive-irule','verb-non-clitic-irule','Cnsntn'),('subir','subido','verb','verb-part-masc-sg-irule','verb-non-clitic-irule','Cnsntn'),('subir','subir','verb','verb-inf-irule','verb-non-clitic-irule','Cnsntn'),('saber','sé','verb','verb-1-sg-present-indicative-irule','verb-non-clitic-irule','Ennssn'),('ti','ti','det','det-2-sg-irule',NULL,NULL),('tener','tienes','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule','Ennnsn'),('toalla','toalla','noun','noun-fem-sg-irule',NULL,'object'),('todo','todo','det','det-masc-sg-irule',NULL,NULL),('tú','tú','det','det-2-sg-irule',NULL,NULL),('un','un','det','det-masc-sg-irule',NULL,NULL),('venir','viene','verb','verb-3-sg-present-indicative-irule','verb-non-clitic-irule','Lnsnen'),('venir','vienes','verb','verb-2-sg-present-indicative-irule','verb-non-clitic-irule','Lnsnen'),('él','él','det','det-masc-sg-irule',NULL,NULL);
/*!40000 ALTER TABLE `form` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-08-30 13:23:12
