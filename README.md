# Królowa Stylu — galeria mody multiplayer

Dwa tematy, wspólny budżet 1500 zł i 8 minut na dwie stylizacje. Od 2 do 8 uczestników robi zakupy, prezentuje oba zestawy i ocenia pozostałych w skali 1–10.

## Uruchomienie

1. Zatrzymaj Play w Studio. W folderze repozytorium wykonaj `git pull origin main`.
2. Uruchom `rojo serve` (Rojo 7.7.1 z `aftman.toml`) lub pozostaw działający serwer. Połącz wtyczkę w Studio i poczekaj na synchronizację.
3. Otwórz kopię `Roblox Shopping queen.rbxl`. Projekt synchronizuje skrypty, zachowując istniejącą mapę. Budynki powstają po Play.
4. Uruchom test serwera z **dwoma klientami**. Przy jednej osobie czekasz w zamkniętym, przeszklonym Style Lounge. Dołączający podczas rundy czekają w salonie na następną.

Alternatywnie `rojo build -o "Ola Roblox.rbxlx"` tworzy miejsce ze skryptami, które generują galerię. Build nie importuje mapy z oryginalnego pliku `.rbxl`. Oryginał pozostaje bez zmian. Zapis i publikacja gry do Roblox należą do właściciela.

## Galeria: 20 sklepów

Galeria ma pasaż o wymiarach 126 × 496 studów, 20 oddzielnych lokali, numerowane szyldy, witryny, wybieg oraz poczekalnię. Podłoga jest na wysokości 8 studów nad oryginalną płytą. Generator zarządza wyłącznie `Workspace.ShoppingQueenPrototype`.

| Lokale | Specjalizacja |
| --- | --- |
| Rose Atelier, Urban Muse, Silk Avenue, Bloom Studio, Atelier Noir, Everyday Edit | Góry ubrań |
| Studio Denim, Maison Plissé, The Tailor, Hemline | Spodnie i spódnice |
| Sole Society, City Steps, Velvet Walk | Buty |
| Bag Stories, Petite Maro | Torebki |
| Golden Details, Pearl Room | Biżuteria |
| Hat Gallery, Crown & Co | Nakrycia głowy |
| Vue Optique | Okulary |

**Oferta jest losowana na początku każdej rundy, nie przy każdym otwarciu sklepu.** Każdy lokal ma trzy produkty z puli sześciu fasonów swojej kategorii, łącznie 60 ofert z 42 wzorów. Serwer losuje także kolory domyślne. Zapewnia co najmniej jeden zmieniony fason w każdym sklepie względem poprzedniej rundy; pojedyncze produkty mogą wracać. Wszyscy gracze widzą tę samą ofertę i ceny. Zakup jednej osoby nie usuwa produktu innym.

Odświeżane są wyłącznie ekspozycje produktów. Budynki, podłoga, poczekalnia i wybieg pozostają na miejscu. Manekiny oraz GUI przedstawiają tę samą aktualną kolekcję. Stary identyfikator wycofanego produktu nie pozwala kupić ani przymierzyć go w nowej rundzie.

## Zakupy i stylizacje

- Dolny przycisk **Sklepy / moje** otwiera katalog lokali z numerami, specjalizacją i stroną pasażu. Wybierz sklep i „Oferta”, albo podejdź do lady/manekina i użyj E lub przycisku interakcji na telefonie.
- Zakładka **Ten sklep** pokazuje aktualne trzy produkty. Pozostałe zakładki pozwalają porównać kategorie w całej galerii; karta wskazuje sklep, do którego trzeba podejść. **Moje** zawiera zakupione produkty.
- **Fason i kolory** otwiera obracany podgląd wybranego produktu na kopii awatara. Dostępnych jest sześć kolorów. Podgląd pokazuje wybrany produkt, nie cały zestaw.
- **Przymierz na postaci** zakłada produkt dla wszystkich oglądających, ale nie zmienia budżetu ani zapisanego zestawu. Wymaga bliskości właściwego sklepu. **Zakończ przymiarkę** przywraca aktualnie skomponowany zestaw.
- Kup produkt, dodaj go do zestawu 1 lub 2 i zapisz. Każdy zestaw wymaga góry i dołu. Można osobno nosić buty, nakrycie głowy, torebkę, biżuterię i okulary. Zmiana jednego dodatku nie zastępuje pozostałych kategorii.
- Ten sam zakup można użyć w obu zestawach, w różnych kolorach. Zmiana koloru jest bezpłatna. Po zmianie wybierz produkt do zestawu i ponownie zapisz zestaw.

Ubrania i dodatki są własnymi stylizowanymi modelami z dopasowanych części, bez wymaganych uploadów assetów. Są wśród nich bluzki, żakiety, gorsety, bluzy, kamizelki, tuniki, różne spódnice/spodnie, buty, torebki, kapelusze, biżuteria i okulary. To nie symulacja tkaniny. Nietypowe ciała, skale i animacje mogą wymagać dopasowania. Lustra są dekoracyjne; podgląd awatara działa w GUI.

## Przebieg rundy

Po 15 sekundach odliczania serwer przenosi uczestników z salonu do pasażu. Po zakupach następuje pierwszy pokaz wszystkich osób, a potem drugi. Niezapisany zestaw pokazuje bazowego awatara. Na ocenę jest 15 sekund; można zagłosować raz, tylko na inną osobę i tylko będąc uczestnikiem.

Wynik to średnia z dwóch średnich pokazów. Pokaz bez głosów ma 0 punktów. Remisy dają wspólne miejsca; głosy osób, które wyszły z rundy, nie są uwzględniane w końcowym rankingu. Wyniki są widoczne przez 20 sekund, potem wszyscy wracają do poczekalni.

Reset postaci zachowuje zakupy w bieżącej rundzie. Wyjście uczestnika powodujące spadek liczby poniżej dwóch przerywa rundę i odsyła pozostałych do salonu. Budżet, garderoba i głosy są zerowane między rundami; brak trwałego zapisu zakupów.

## GUI i przyszły sklep za Robuxy

Menu obejmuje Salon, Sklepy / moje, Butik + i Zasady. Podczas pokazu przycisk sklepów prowadzi do ocen, a po finale do wyników. B otwiera Butik +, M otwiera Salon; okna zamyka się przyciskiem ×.

**Butik + zawiera wyłącznie zapowiedzi dodatków.** Nie ma cen, identyfikatorów płatnych produktów, okien płatności ani przyznawania korzyści. Budżet rundy jest oddzielny od Robuxów. Uruchomienie sprzedaży będzie wymagało osobnego przygotowania produktów w Roblox oraz obsługi uprawnień i potwierdzania zakupów na serwerze.

## Kod i testy

- `src/shared/Mall.luau`: lokale, 42 wzory i losowanie wspólnego asortymentu.
- `Config.luau`: czas, budżet, tematy i paleta.
- `Garments.luau`: geometria ekspozycji, podglądu oraz ubrań na postaci.
- `Rules.luau`: budżet, własność, kolor, zestawy i głosy.
- `src/server/World.luau`: mapa i wymiana ekspozycji.
- `src/client/UI.luau` i `init.client.luau`: wygląd i interakcje GUI.

```sh
luau tests/rules.luau
luau tests/ui_state.luau
luau tests/mall.luau
python tests/check_world.py
rojo build -o "Ola Roblox.rbxlx"
```

`check_world.py` wymaga Pythona 3 oraz `luau` w PATH lub zmiennej `LUAU_BIN`. Sprawdza generator mapy na uproszczonych obiektach silnika: wejścia do 20 sklepów, 60 interakcji produktów, podłogi, zamknięty salon i odświeżanie ekspozycji. Buduje też wszystkie 42 wzory na modelach zastępczych R6/R15. Nie sprawdza renderowania, fizyki ani animacji prawdziwych awatarów. Fixture w `tests/fixtures/Catalog.luau` służy wyłącznie testom reguł; nie jest ofertą gry.

### Kontrola ręczna w Studio

1. Na jednym kliencie sprawdź salon, okna, siedzenie i brak możliwości wyjścia. Na dwóch klientach sprawdź przeniesienie do galerii po odliczaniu, także po siedzeniu na kanapie.
2. Sprawdź 20 lokali i katalog GUI. Oba klienty muszą widzieć te same produkty, ceny i ekspozycje. Zakup z daleka lub w niewłaściwym sklepie ma być odrzucony.
3. Przetestuj przymiarkę, zmianę koloru, cofnięcie przymiarki, zakup i dwie zapisane stylizacje. Sprawdź łączne noszenie torby, biżuterii, okularów i kapelusza oraz reset postaci.
4. Przejdź pełną rundę. Następna ma zmienić ofertę każdego sklepu i wyzerować zakupy; na wystawach nie mogą pozostać stare manekiny ani podwójne interakcje.
5. Sprawdź oba pokazy, kamerę, własne/powtórne głosy, ranking, wyjście uczestnika i dołączenie obserwatora w trakcie.
6. Sprawdź klatkaż całej galerii, awatary R6/R15, chodzenie w ubraniach oraz GUI i dotyk w emulatorze telefonu.

Po aktualizacji zatrzymaj Play, poczekaj na Rojo i uruchom Play ponownie. Zmieniony generator nie przebuduje trwającej już sesji testowej automatycznie.
