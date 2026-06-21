# Spieler-Anleitung

Mit der **Sections**-Mod kannst du größere Bauflächen in der Welt schützen, damit niemand
(außer dir und deinen Freunden) dort Blöcke abbaut oder setzt. Die Welt ist in 16×16×16 große **Sections** aufgeteilt.

## Das Section Protection Tool

Nimm das Tool in die Hand und schaue auf einen beliebigen Block. Wenn du das
Tool benutzt, wirkt es auf die **vier Sections, die vertikal übereinander
an der X/Z-Position dieses Blocks** liegen:

- die **Section des Blocks selbst** (Ebene 0)
- die **Section darunter** (Ebene −1)
- die **Section direkt darüber** (Ebene +1)
- die **Section zwei Blöcke darüber** (Ebene +2)

Alle vier Sections haben die gleiche X/Z-Position; sie unterscheiden sich nur
in der Y-Stufe. Die Section-Nummern werden vom Section-Schutzmod in einer
Zeichenkette wie `N710W658U1` kodiert (Nord/Süd, West/Ost, Unten/Oben +
Index).

### Linksklick / Schlag auf einen Block

Zeigt im Chat an, wem die 4 Sections um den Block gehören. Member (zusätzliche
Spieler mit Zugriff auf die Section) werden in Klammern hinter dem Besitzer
angezeigt, alphabetisch sortiert:

```
+2: SpielerName
+1: SpielerName (member1, member2)
 0: no protection
-1: SpielerName
```

Zusätzlich wird die mittlere Section (Ebene 0) für 60 Sekunden mit einem blauen Rahmen markiert.

### Rechtsklick / Setzen auf einen Block

Schützt die noch freien der 4 Sections auf dich. Auf diesem Server kostet das **3 Goldbarren** aus deinem 
Inventar (Standardeinstellung der Mod: 4 Diamanten – kann vom Server-Admin geändert werden).
Sections, die schon jemandem gehören, bleiben unangetastet. Nach dem Schutz werden die neu beanspruchten
Sections für 60 Sekunden mit blauen Rahmen markiert.

### Was passiert, wenn nicht genug Gold da ist?

Es passiert **nichts** und du bekommst eine Chat-Meldung. Kein Item-Verlust.

## Freunde / Co-Owner

Du kannst anderen Spielern Rechte an deinen Sections geben (du musst Owner sein).
Alle Kommandos wirken jeweils auf **die Section, in der du gerade stehst**
(und nicht auf alle 4 übereinander liegenden Sections):

- `/section_change_owner <Name>` – neuen Owner festlegen (du verlierst den Schutz)
- `/section_add_player <Name>` – Spieler zur aktuellen Section hinzufügen
- `/section_remove_player <Name>` – Spieler wieder entfernen
- `/section_delete` – deine 4 Sections (Y=-1..+2) komplett freigeben. Die
  Schutz­kosten werden dir dabei **zurückerstattet**.

## Anzeige im HUD

Während du dich in einer geschützten Section aufhältst, zeigt eine kleine Anzeige oben rechts:

```
Besitzer: SpielerName [Section]
```

## Exakter Block-für-Block-Schutz mit der Protector-Mod

Wenn du nur einen ganz kleinen Bereich (z.B. eine einzelne Maschine, eine Truhe oder einen Marktstand)
schützen willst, der **nicht** in das 16×16×16-Raster passt, nutze die **Protector**-Mod:

- **Schutzblock craften** (Rezept variiert je nach Server-Setup – üblich ist
  3×3 Stein mit einem Gold- oder Silberbarren in der Mitte; das genaue
  Rezept legt die Protector-Mod fest)
- **Platzieren** – der Block schützt standardmäßig einen Würfel von 5 Blöcken Radius um sich herum
- Als Owner kannst du Mitglieder hinzufügen

> Hinweis: Ein Protector-Block **innerhalb** einer geschützten Section ändert **nichts** am Section-Schutz. 
> Beide Systeme schützen unabhängig voneinander.

## Wo sind die Section-Grenzen?

Die Sections beginnen am Welt-Ursprung (Koordinate 0/0/0) und reichen in 16er-Schritten:

- X: 0..15, 16..31, 32..47, …
- Y: -16..-1, 0..15, 16..31, …
- Z: 0..15, 16..31, 32..47, …

Eine Section-ID wie `N710W658U1` bedeutet: Nord, X-Achse 658, Oben (Up), Y-Achse 1.

