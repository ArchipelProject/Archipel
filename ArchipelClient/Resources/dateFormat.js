//
// dateFormat v0.1 | 2004-04-03 15:10
//
// a : Ante meridiem et Post meridiem en minuscules - am ou pm 
// A : Ante meridiem et Post meridiem en majuscules - AM ou PM 
// B : Heure Internet Swatch - 000 à 999
//     http://www.quirksmode.org/index.html?/js/beat.html
// d : Jour du mois, sur deux chiffres avec zéro initial - 01 à 31 
// D : Jour de la semaine, en 3 lettres, anglais par défaut - Mon à Sun 
// F : Mois textuel, version longue, anglais par défaut - January à December 
// g : Heure au format 12h, sans le zéro initial - 1 à 12 
// G : Heure au format 24h, sans le zéro initial - 0 à 23 
// h : Heure au format 12h, avec le zéro initial - 01 à 12 
// H : Heure au format 24h, avec le zéro initial - 00 à 23 
// i : Minutes avec le zéro initial - 00 à 59 
// j : Jour du mois sans le zéro initial - 1 à 31 
// l : Jour de la semaine, textuel, anglais par défaut - Sunday à Saturday 
// L : L'année est elle bissextile ? - 0 ou 1 
// m : Mois avec le zéro intial - 01 à 12 
// M : Mois, en 3 lettres, anglais par défaut - Jan à Dec 
// n : Mois sans le zéro intial - 1 à 12 
// O : Différence avec l'heure de Greenwich (GMT), en heures - -1200 à +1200 
// r : Format de date RFC 822 Thu, 1 Apr 2004 12:00:00 - +0200 
// s : Secondes avec le zéro initial - 00 à 59 
// S : Suffixe ordinal d'un jour, anglais par défaut - st, nd, rd, th 
// t : Nombre de jours dans le mois - 28 à 31 
// U : Secondes depuis le 1er Janvier 1970, 0h00 00s GMT - Ex: 1081072800 
// w : Jour de la semaine (0 étant dimanche, 6 samedi) - 0 à 6 
// W : Numéro de la semaine dans l'année - 1 à 52
//     http://www.asp-php.net/tutorial/asp-php/glossaire.php?glossid=28
// y : Année sur 2 chiffres - Ex: 04 
// Y : Année sur 4 chiffres - Ex: 2004 
// z : Jour de l'année - 1 à 366 
// Z : Décalage horaire en secondes - -43200 à 43200 
// \ : Caractère d'echappement - Ex: \a, \A, \m

String.prototype.padLeft = function(strChar, intLength)
{
 var str = this + '';
 while (str.length != intLength) {
  str = strChar + str;
 }
 return str;
}

String.prototype.isInt = function()
{
 var oRegExp = new RegExp(/\d+/);
 return oRegExp.test(this);
}

Array.prototype.exists = function(objValue)
{
 var boolReturn = false, i = 0;
 for (i = 0; i < this.length; i++) {
  if (this[i] == objValue) {
   boolReturn = true;
   break;
  }
 }
 return boolReturn;
}

Date.prototype.dateFormat = function(strFormat, strLang, intTime)
{

 var arrayLang = ['en', 'fr'];
 var arrayFunctions = ['a', 'A', 'B', 'd', 'D', 'F', 'g', 'G', 'h', 'H', 'i', 'j', 'l', 'L', 'm', 'M', 'n', 'O', 'r', 's', 'S', 't', 'U', 'w', 'W', 'y', 'Y', 'z', 'Z'];

 if (intTime) {
  if (!intTime.toString().isInt()) {
   intTime = null;
  } else {
   intTime *= 1000;
  }
 }
 if (strLang) {
  if (strLang.toString().isInt()) {
   intTime = strLang * 1000;
   strLang = 'en';
  } else {
   if (!arrayLang.exists(strLang)) {
    strLang = 'en';
   }
  }
 } else {
  strLang = 'en';
 }

 var arrayDays_en = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
 var arrayMonths_en = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
 var arraySuffix_en = ['st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th', 'th', 'st'];

 var arrayDays_fr = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
 var arrayMonths_fr = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
 var arraySuffix_fr = ['er', 'nd', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème', 'ème'];

 // a : Ante meridiem et Post meridiem en minuscules - am ou pm 
 fct_a = function()
 {
  return (self.getHours() > 11) ? 'pm' : 'am';
 }

 // A : Ante meridiem et Post meridiem en majuscules - AM ou PM 
 fct_A = function()
 {
  return (self.getHours() > 11) ? 'PM' : 'AM';
 }

 // B : Heure Internet Swatch - 000 à 999
 //     http://www.quirksmode.org/index.html?/js/beat.html
 fct_B = function() {
  var intGMTOffset = (self.getTimezoneOffset() + 60) * 60;
  var intSeconds = (self.getHours() * 3600) + (self.getMinutes() * 60) + self.getSeconds() + intGMTOffset;
  var intBeat = Math.floor(intSeconds / 86.4);
  if (intBeat > 1000) {intBeat -= 1000;}
  if (intBeat < 0) {intBeat += 1000;}
  return intBeat.toString().padLeft('0', 3);
 }

 // d : Jour du mois, sur deux chiffres avec zéro initial - 01 à 31 
 fct_d = function()
 {
  return self.getDate().toString().padLeft('0', 2);
 }

 // D : Jour de la semaine, en 3 lettres, anglais par défaut - Mon à Sun 
 fct_D = function()
 {
  return eval('arrayDays_' + strLang)[self.getDay()].substring(0, 3);
 }

 // F : Mois textuel, version longue, anglais par défaut - January à December 
 fct_F = function()
 {
  return eval('arrayMonths_' + strLang)[self.getMonth()];
 }

 // g : Heure au format 12h, sans le zéro initial - 1 à 12 
 fct_g = function()
 {
  return (self.getHours() > 12) ? self.getHours() - 12 : self.getHours();
 }

 // G : Heure au format 24h, sans le zéro initial - 0 à 23 
 fct_G = function()
 {
  return self.getHours();
 }

 // h : Heure au format 12h, avec le zéro initial - 01 à 12 
 fct_h = function()
 {
  return (self.getHours() > 12) ? (self.getHours() - 12).toString().padLeft('0', 2) : self.getHours().toString().padLeft('0', 2);
 }

 // H : Heure au format 24h, avec le zéro initial - 00 à 23 
 fct_H = function()
 {
  return self.getHours().toString().padLeft('0', 2);
 }

 // i : Minutes avec le zéro initial - 00 à 59 
 fct_i = function()
 {
  return self.getMinutes().toString().padLeft('0', 2);
 }

 // j : Jour du mois sans le zéro initial - 1 à 31 
 fct_j = function()
 {
  return self.getDate();
 }

 // l : Jour de la semaine, textuel, anglais par défaut - Sunday à Saturday 
 fct_l = function()
 {
  return eval('arrayDays_' + strLang)[self.getDay()];
 }

 // L : L'année est elle bissextile ? - 0 ou 1 
 fct_L = function()
 {
  var intFullYear = fct_Y();
  return ((intFullYear % 4 == 0 && intFullYear % 100 != 0) || (intFullYear % 4 == 0 && intFullYear % 100 == 0 && intFullYear % 400 == 0)) ? 1 : 0;
 }

 // m : Mois avec le zéro intial - 01 à 12 
 fct_m = function()
 {
  return (self.getMonth() + 1).toString().padLeft('0', 2);
 }

 // M : Mois, en 3 lettres, anglais par défaut - Jan à Dec 
 fct_M = function()
 {
  return eval('arrayMonths_' + strLang)[self.getMonth()].substring(0, 3);
 }

 // n : Mois sans le zéro intial - 1 à 12 
 fct_n = function()
 {
  return (self.getMonth() + 1);
 }

 // O : Différence avec l'heure de Greenwich (GMT), en heures - -1200 à +1200 
 fct_O = function()
 {
  var intTimezone = self.getTimezoneOffset();
  var intTimezoneAbs = Math.abs(intTimezone);
  var strTimezone = Math.floor(intTimezoneAbs / 60).toString().padLeft('0', 2) + (intTimezoneAbs % 60).toString().padLeft('0', 2);
  return (intTimezone < 0) ? '+' + strTimezone : '-' + strTimezone ;
 }

 // r : Format de date RFC 822 Thu, 1 Apr 2004 12:00:00 - +0200 
 fct_r = function()
 {
  return fct_D() + ', ' + fct_j() + ' ' + fct_M() + ' ' + fct_Y() + ' ' + fct_H() + ':' + fct_i() + ':' + fct_s() + ' ' + fct_O();
 }

 // s : Secondes avec le zéro initial - 00 à 59 
 fct_s = function()
 {
  return (self.getSeconds()).toString().padLeft('0', 2);
 }

 // S : Suffixe ordinal d'un jour, anglais par défaut - st, nd, rd, th 
 fct_S = function()
 {
  return eval('arraySuffix_' + strLang)[self.getDate() - 1];
 }

 // t : Nombre de jours dans le mois - 28 à 31 
 fct_t = function()
 {
  var intDays = 0;
  if (self.getMonth() == 1) {
   intDays = 28 + fct_L();
  } else {
   switch (self.getMonth() % 2) {
    case 0 : intDays = 31; break;
    default : intDays = 30;
   }
  }
  return intDays;
 }

 // U : Secondes depuis le 1er Janvier 1970, 0h00 00s GMT - Ex: 1081072800 
 fct_U = function()
 {
  return Math.round(self.getTime() / 1000);
 }

 // w : Jour de la semaine (0 étant dimanche, 6 samedi) - 0 à 6 
 fct_w = function()
 {
  return self.getDay();
 }

 // W : Numéro de la semaine dans l'année - 1 à 52
 //     http://www.asp-php.net/tutorial/asp-php/glossaire.php?glossid=28
 fct_W = function()
 {
  return Math.floor((fct_z() - 1 - self.getDay()) / 7) + 2;
 }

 // y : Année sur 2 chiffres - Ex: 04 
 fct_y = function()
 {
  var strFullYear = fct_Y().toString();
  return strFullYear.substring(strFullYear.length - 2, strFullYear.length);
 }

 // Y : Année sur 4 chiffres - Ex: 2004 
 fct_Y = function()
 {
  return self.getFullYear();
 }

 // z : Jour de l'année - 1 à 366 
 fct_z = function()
 {
  var datePremierJanvier = new Date('January 1 ' + fct_Y().toString() + ' 00:00:00');
  var intDifference = self.getTime() - datePremierJanvier.getTime();
  return Math.floor(intDifference / 1000 / 60 / 60 / 24);
 }

 // Z : Décalage horaire en secondes - -43200 à 43200 
 fct_Z = function()
 {
  var intTimezone = self.getTimezoneOffset();
  var intTimezoneAbs = Math.abs(intTimezone);
  var strTimezone = intTimezoneAbs * 60;
  return (intTimezone < 0) ? strTimezone : -strTimezone ;
 }

 var self = this;
 if (intTime) {
  var intMyTime = self.getTime();
  self.setTime(intTime);
 }
 var arrayFormat = strFormat.split(''), i = 0;
 for (i = 0; i < arrayFormat.length; i++) {
  if (arrayFormat[i] == '\\') {
   arrayFormat.splice(i, 1);
  } else {
   if (arrayFunctions.exists(arrayFormat[i])) {
    arrayFormat[i] = eval('fct_' + arrayFormat[i] + '();');
   }
  }
 }
 if (intMyTime) {
  self.setTime(intMyTime);
 }
 return arrayFormat.join('');

}