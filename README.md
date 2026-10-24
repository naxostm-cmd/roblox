# Królowa Stylu — prototyp multiplayer

Dwa różne tematy, wspólny budżet 1500 zł, 8 minut zakupów i dwa pokazy każdej osoby. Do rundy losowane jest od 2 do 8 graczy. Osoby dołączające później obserwują i czekają na kolejną rundę.

## Roblox Studio + Rojo

1. W folderze repozytorium wykonaj `git pull origin main`.
2. Użyj Rojo **7.7.1** (wersja w `aftman.toml`). Uruchom `rojo serve` w folderze z `default.project.json`.
3. Otwórz kopię `Roblox Shopping queen.rbxl` w Studio, połącz wtyczkę Rojo i przejrzyj zmiany synchronizacji. Projekt synchronizuje skrypty, zachowując istniejącą mapę i pozostałe usługi.
4. Uruchom test serwera z **dwoma klientami** w narzędziach testowych Studio. Przy jednym graczu czekasz w przeszklonym salonie z widokiem na galerię. Do rozpoczęcia zakupów potrzeba dwóch osób.

Alternatywnie: `rojo build -o "Ola Roblox.rbxlx"`. Wynik zawiera skrypty, ale **nie importuje mapy z oryginalnego pliku `.rbxl`**. Serwer tworzy zabudowaną galerię 126 × 160 studów: cztery butiki z witrynami, manekinami i wieszakami, pasaż pod szklanym dachem, ławki, rośliny i strefę pokazów. Budynki pojawiają się po Play, nie w trybie edycji. Podłoga znajduje się na wysokości 8 studów nad oryginalną płytą, a powierzchnie butików są oddzielone od posadzki, żeby uniknąć migotania. Zarządza wyłącznie swoim folderem `Workspace.ShoppingQueenPrototype`. Jeśli istniejąca mapa zajmuje ten sam obszar, dostosuj współrzędne w `src/server/World.luau`.

## Jak grać

- Poczekalnia to osobny, zamknięty Style Lounge wewnątrz galerii: przez szyby widać pasaż, a wewnątrz są dwie kanapy (6 miejsc siedzących), stolik, magazyny, rośliny i oświetlenie. Nie można wyjść do sklepów przed rundą. Po odliczaniu serwer przenosi wybranych uczestników do pasażu. Pozostali oraz osoby dołączające w trakcie rundy zostają w salonie.
- Po 15 sekundach lobby runda losuje dwa różne tematy. Budżet jest wspólny dla obu stylizacji i nie ma związku z Robuxami.
- Podejdź do stoiska i użyj interakcji (E na klawiaturze). Zakupy i przymiarki wymagają bliskości odpowiedniego sklepu. Przymiarka nie zapisuje produktu ani nie pobiera pieniędzy.
- Wybierz zestaw 1 lub 2. Kupiony produkt dodaj przyciskiem „Wybierz do zestawu”. W garderobie dostępne są wszystkie zakupione produkty; można wykorzystać je w obu zestawach.
- Zapisz **oba** zestawy. Każdy wymaga góry i dołu. Po zmianie produktu zapisz zestaw ponownie.
- Po czasie pokazywany jest najpierw pierwszy temat wszystkich osób, potem drugi. Niezapisany zestaw prezentuje bazowego awatara. Każdy pokaz daje 15 sekund na ocenę 1–10. Tylko uczestnicy mogą głosować, raz na pokaz, bez głosowania na siebie.
- Wynik to średnia z dwóch średnich pokazów. Pokaz bez głosów ma 0 punktów. Remisy dają wspólne miejsca. Głosy osób, które opuściły rundę, nie są liczone w końcowym rankingu.
- Wyniki są widoczne przez 20 sekund. Następna runda zeruje zakupy i budżet. Brak zapisu między rundami i serwerami.
- Gdy zostanie mniej niż dwóch uczestników, runda wraca do lobby. Reset postaci nie usuwa zakupów.

## Zakres prototypu

Ubrania są wizualizowane jako kolory części awatara, proste buty i kapelusze. To nie docelowe modele sukienek ani zakupy katalogowe. Obsługiwane są nazwy części R6/R15; niestandardowe awatary, warstwowe ubrania i nietypowe skale wymagają sprawdzenia w Studio. Galeria ma już budynki, lecz docelowe modele i tekstury ubrań pozostają kolejnym etapem.

Ceny, tematy i czas zmienisz w `src/shared/Config.luau`. Reguły zakupów, zapisów i ocen są w `src/shared/Rules.luau`. Serwer sprawdza budżet, własność produktów, dystans do sklepu, etap rundy i uprawnienia do głosowania. Klient obsługuje UI oraz kamerę.

## Testy

Z interpreterem Luau i Rojo w PATH:

```sh
luau tests/rules.luau
luau tests/ui_state.luau
python tests/check_world.py
rojo build -o "Ola Roblox.rbxlx"
```

Testy reguł sprawdzają brak środków, ponowne zakupy, niezależność zestawów, zapis, nieprawidłowe i własne głosy, obserwatorów, wyjście gracza i remisy. Test `check_world.py` wymaga Pythona 3 oraz interpretera `luau` w PATH (lub zmiennej `LUAU_BIN`). Uruchamia generator mapy z uproszczonymi obiektami silnika i sprawdza cztery interakcje sklepów, przejście od pasażu do lad, rozdzielenie podłóg i zachowanie istniejącej mapy, zamknięcie salonu z każdej strony, przezroczystość okien, sześć siedzeń oraz wolne miejsce odradzania. Nie sprawdza renderowania ani fizyki Roblox i nie zastępuje testu multiplayer w Studio.

### Kontrola ręczna w Studio

Do szybkiego testu tymczasowo zmniejsz `ShoppingSeconds` i `VotingSeconds`, a potem przywróć wartości:

1. Uruchom jeden klient: postać ma pojawić się w Style Lounge. Sprawdź widok na galerię przez okna, siedzenie na kanapie, zamknięte drzwi, próby skakania nad ścianami i reset postaci. Postać ma pozostać w salonie, a runda nie może ruszyć.
2. Uruchom drugi klient i podczas odliczania usiądź na kanapie. Po starcie zakupów obie postacie mają znaleźć się w pasażu, bez przyciągania kanapy. Sprawdź jednakowe tematy i budżety, wejścia do butików i brak migotania podłogi. Reset postaci podczas zakupów ma odrodzić uczestnika w pasażu.
3. Przymierz produkt: budżet i zestawy nie powinny się zmienić. Kup: budżet spada tylko raz. Zakup z daleka lub bez środków ma być odrzucony.
4. Zapisz dwa różne zestawy. Sprawdź odrzucenie zapisu bez góry/dołu oraz konieczność ponownego zapisu po zmianie. Zresetuj postać i sprawdź zachowanie garderoby.
5. Sprawdź oba pokazy każdej osoby, kamerę i oceny. Nie można oceniać siebie ani głosować ponownie. Porównaj ranking z oddanymi ocenami.
6. Dołącz trzecim klientem podczas zakupów: ma zostać w zamkniętym salonie bez zakupów i głosowania. Wyjdź jednym z dwóch uczestników: gra ma wrócić do salonu, odblokować postać i przywrócić kamerę.
7. Sprawdź kolejną rundę, powrót do salonu po wynikach, reset stanu, UI w emulatorze telefonu i awatary R6/R15.

`Roblox Shopping queen.rbxl` pozostaje oryginałem. Rojo zmienia otwarty projekt Studio; zapis i publikacja gry do Roblox należą do właściciela.

Po pobraniu aktualizacji zatrzymaj Play przyciskiem Stop, poczekaj na synchronizację Rojo i dopiero uruchom Play ponownie. Moduły generujące mapę nie przebudują jej w już trwającym teście.

Salon pozostaje fizycznie zamknięty także podczas zakupów, aby obserwatorzy nie mogli wyjść za uczestnikami. Oprócz kolizji ścian serwer co 0,5 sekundy sprawdza obszar oczekiwania. Aktywni uczestnicy zakupów i aktualny prezenter mają odpowiednio dostęp do pasażu i wybiegu. Reset oraz upadek postaci nie omijają poczekalni.

## Interfejs i Butik +

Interfejs ma kremową paletę z różowymi i złotymi akcentami: kompaktowy panel rundy z tematami, zegarem, paskiem czasu i budżetem, dolne menu oraz przewijane karty. Układ dostosowuje szerokość do okna i korzysta z obszaru bezpiecznego Roblox. Nie ukrywa systemowego menu ani sterowania.

- **Salon** — powitanie, informacje o poczekalni i przejście do zapowiedzi dodatków.
- **Stylizacje** — garderoba i zakupy za złotówki rundy; w czasie pokazu ten przycisk prowadzi do ocen, a po finale do wyników.
- **Butik +** — osobna kolekcja przyszłych dodatków za Robuxy: VIP Style, Rose Aura, Runway Poses i Golden Entrance. Karty i szczegóły są wyłącznie zapowiedziami, bez ceny i bez możliwości zapłaty. Nie pojawia się okno płatności, nie ma produktu do odebrania ani nadawania korzyści.
- **Zasady** — instrukcja rozgrywki. Na klawiaturze B otwiera Butik +, M otwiera Salon. Każde okno można zamknąć przyciskiem ×.

Zapowiedzi edytuje się w `src/shared/PremiumCatalog.luau`; wygląd elementów w `src/client/UI.luau`. Kod nie zawiera identyfikatorów płatnych produktów ani obsługi MarketplaceService. Uruchomienie sprzedaży będzie osobnym zadaniem: trzeba zdefiniować produkty/passy w Roblox, pobierać rzeczywiste ceny i bezpiecznie potwierdzać uprawnienia oraz przyznawanie zakupów na serwerze. Budżet rundy pozostaje oddzielny od Robuxów.

`tests/ui_state.luau` sprawdza przełączanie ekranów: aktualizacje budżetu nie zamykają Butiku +, otwarcie lady prowadzi do garderoby tylko uczestnika, a nowy pokaz otwiera ocenianie. Testy te nie sprawdzają wyglądu w silniku Roblox.

### Kontrola GUI w Studio

1. Po Stop → synchronizacja Rojo → Play sprawdź HUD, powitanie i cztery pozycje menu. Otwórz każdą stronę, przewiń ją, użyj ×, M i B.
2. W Butiku + otwórz szczegóły każdej karty, wróć do kolekcji i potwierdź brak płatności, zmiany budżetu oraz przyznania przedmiotów.
3. Na dwóch klientach przetestuj zakup za złotówki, zmianę zestawu, zapis, oceny 1–10 i wyniki. Panel ocen powinien pozostawić widoczny wybieg; własne i powtórne głosy pozostają blokowane przez serwer.
4. Podczas oczekiwania w Butiku + sprawdź przejście do nowego pokazu. Po zamknięciu ocen można je ponownie otworzyć dolnym przyciskiem. Reset postaci nie powinien usuwać GUI.
5. W emulatorze telefonu sprawdź pion i poziom, przewijanie kart, wszystkie przyciski i widoczność interfejsu przy systemowych kontrolkach. Renderowanie, dotyk i obsługa kamery wymagają testu w Studio; build CLI ich nie zastępuje.
