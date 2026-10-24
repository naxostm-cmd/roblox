# Królowa Stylu — prototyp multiplayer

Dwa różne tematy, wspólny budżet 1500 zł, 8 minut zakupów i dwa pokazy każdej osoby. Do rundy losowane jest od 2 do 8 graczy. Osoby dołączające później obserwują i czekają na kolejną rundę.

## Roblox Studio + Rojo

1. W folderze repozytorium wykonaj `git pull origin main`.
2. Użyj Rojo **7.7.1** (wersja w `aftman.toml`). Uruchom `rojo serve` w folderze z `default.project.json`.
3. Otwórz kopię `Roblox Shopping queen.rbxl` w Studio, połącz wtyczkę Rojo i przejrzyj zmiany synchronizacji. Projekt synchronizuje skrypty, zachowując istniejącą mapę i pozostałe usługi.
4. Uruchom test serwera z **dwoma klientami** w narzędziach testowych Studio. Test jednoosobowy zatrzyma się w lobby.

Alternatywnie: `rojo build -o "Ola Roblox.rbxlx"`. Wynik zawiera skrypty, ale **nie importuje mapy z oryginalnego pliku `.rbxl`**. Serwer tworzy prostą podłogę, cztery stoiska i wybieg do testowania. Zarządza wyłącznie swoim folderem `Workspace.ShoppingQueenPrototype`. Jeśli istniejąca mapa zajmuje ten sam obszar, dostosuj współrzędne w `src/server/World.luau`.

## Jak grać

- Po 15 sekundach lobby runda losuje dwa różne tematy. Budżet jest wspólny dla obu stylizacji i nie ma związku z Robuxami.
- Podejdź do stoiska i użyj interakcji (E na klawiaturze). Zakupy i przymiarki wymagają bliskości odpowiedniego sklepu. Przymiarka nie zapisuje produktu ani nie pobiera pieniędzy.
- Wybierz zestaw 1 lub 2. Kupiony produkt dodaj przyciskiem „Wybierz do zestawu”. W garderobie dostępne są wszystkie zakupione produkty; można wykorzystać je w obu zestawach.
- Zapisz **oba** zestawy. Każdy wymaga góry i dołu. Po zmianie produktu zapisz zestaw ponownie.
- Po czasie pokazywany jest najpierw pierwszy temat wszystkich osób, potem drugi. Niezapisany zestaw prezentuje bazowego awatara. Każdy pokaz daje 15 sekund na ocenę 1–10. Tylko uczestnicy mogą głosować, raz na pokaz, bez głosowania na siebie.
- Wynik to średnia z dwóch średnich pokazów. Pokaz bez głosów ma 0 punktów. Remisy dają wspólne miejsca. Głosy osób, które opuściły rundę, nie są liczone w końcowym rankingu.
- Wyniki są widoczne przez 20 sekund. Następna runda zeruje zakupy i budżet. Brak zapisu między rundami i serwerami.
- Gdy zostanie mniej niż dwóch uczestników, runda wraca do lobby. Reset postaci nie usuwa zakupów.

## Zakres prototypu

Ubrania są wizualizowane jako kolory części awatara, proste buty i kapelusze. To nie docelowe modele sukienek ani zakupy katalogowe. Obsługiwane są nazwy części R6/R15; niestandardowe awatary, warstwowe ubrania i nietypowe skale wymagają sprawdzenia w Studio. Kolejny etap to własne zasoby ubrań i mapa sklepów.

Ceny, tematy i czas zmienisz w `src/shared/Config.luau`. Reguły zakupów, zapisów i ocen są w `src/shared/Rules.luau`. Serwer sprawdza budżet, własność produktów, dystans do sklepu, etap rundy i uprawnienia do głosowania. Klient obsługuje UI oraz kamerę.

## Testy

Z interpreterem Luau i Rojo w PATH:

```sh
luau tests/rules.luau
rojo build -o "Ola Roblox.rbxlx"
```

Testy reguł sprawdzają brak środków, ponowne zakupy, niezależność zestawów, zapis, nieprawidłowe i własne głosy, obserwatorów, wyjście gracza i remisy. Nie zastępują testu multiplayer w Studio.

### Kontrola ręczna w Studio

Do szybkiego testu tymczasowo zmniejsz `ShoppingSeconds` i `VotingSeconds`, a potem przywróć wartości:

1. Uruchom dwa klienty. Sprawdź jednakowe tematy i budżety. Przy jednej osobie runda nie może ruszyć.
2. Przymierz produkt: budżet i zestawy nie powinny się zmienić. Kup: budżet spada tylko raz. Zakup z daleka lub bez środków ma być odrzucony.
3. Zapisz dwa różne zestawy. Sprawdź odrzucenie zapisu bez góry/dołu oraz konieczność ponownego zapisu po zmianie. Zresetuj postać i sprawdź zachowanie garderoby.
4. Sprawdź oba pokazy każdej osoby, kamerę i oceny. Nie można oceniać siebie ani głosować ponownie. Porównaj ranking z oddanymi ocenami.
5. Dołącz trzecim klientem podczas zakupów: ma obserwować bez zakupów i głosowania. Wyjdź jednym z dwóch uczestników: gra ma wrócić do lobby, odblokować postać i przywrócić kamerę.
6. Sprawdź kolejną rundę, reset stanu, UI w emulatorze telefonu i awatary R6/R15.

`Roblox Shopping queen.rbxl` pozostaje oryginałem. Rojo zmienia otwarty projekt Studio; zapis i publikacja gry do Roblox należą do właściciela.
