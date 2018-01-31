with Ada.Text_IO;
use Ada.Text_IO;
with Ada.Calendar;  use Ada.Calendar;
with Ada.Numerics.Elementary_Functions;
with ada.numerics.float_random;


procedure Main is

   CzyHamulecWcisniety: Boolean := False with Atomic;
   SilaHamowania : Float := 0.0 with Atomic;
   PredkoscAuta : Float := 25.0 with Atomic; -- w metrach na sekunde
   MasaAuta : Float := 900.0;
   PrzyspieszenieZiemskie : Float := 10.0;
   WspoczynnikPodloza : Float := 0.7 with Atomic;
   WspoczynnikPodlozaPodstawa : Float := 0.7 with Atomic;

   ABSwlaczony : Boolean := False with Atomic;



   -- zmniejsza/zwieksza sile hamowania
   -- na podstawie sygnalow z czujnika
   -- wejsciem info czy kola zablokowane
   task type SterownikABS is
   end SterownikABS;

   -- dostaje sygnal ze hamulec zostal nacisniety
   -- po tym sprawdza co ustalony czas czy kola sie nie zablokowaly
   -- oblicza aktualny wpsolczynnik tarcia statycznego
   -- sila hamulca przez m*g
   -- if aktualny_wsp>podloze_wsp => kola zablokowane
   -- wejsciem moze byc boolean czyHamulecNacisniety
   task type Czujnik is
   end Czujnik;

   -- po prostu hamulec
   -- na poczatku sila stala
   -- po wlaczeniu ABSu zmieniamy wedlug zalecen ABSu
   -- wejscie sila z jaka hamujemy
   -- wysyla sygnal do czujnika ze dziala
   task type Hamulec is
      entry Start (ABSo : in SterownikABS; Czujniko : in Czujnik);
   end Hamulec;

   -- na poczatku wspolczynnik staly
   -- potem randomo bedziemy zmieniac w tasku
   task type Podloze is
   end Podloze;


   procedure ObliczaniePredkosci is
      EnergiaPoczatkowa : Float :=0.0;
      DrogaPrzebyta : Float;
      PredkoscInteger : Integer;
      Zmienna : Float;
   begin
      EnergiaPoczatkowa := 0.5*MasaAuta*PredkoscAuta*PredkoscAuta;
            -- obliczamy droge przebyta przez 1 sekunde
            DrogaPrzebyta := PredkoscAuta/10.0;
            -- obliczamy predkosc po jednej sekundzie dzialania sily hamowania
            --
            Zmienna :=  EnergiaPoczatkowa-SilaHamowania*DrogaPrzebyta;
            if Zmienna >= 0.0 then
               PredkoscAuta := Ada.Numerics.Elementary_Functions.Sqrt(2.0*(Zmienna)/MasaAuta); -- to powinno byc w pierwiastku
            else
               PredkoscAuta := 0.0;
            end if;

            PredkoscInteger := Integer(PredkoscAuta);
            Put_Line(PredkoscInteger'Img);
   end ObliczaniePredkosci;



   task body Hamulec is

   begin
      accept Start (ABSo : in SterownikABS; CzujnikO : in Czujnik) do
         Put_Line("Hamulec nacisniety");
         SilaHamowania := 5825.0;
         CzyHamulecWcisniety := True;
         delay 0.2;
         while PredkoscAuta > 0.0 and ABSwlaczony = False loop
            Put_Line("hamulec bez absu");
            --obliczamy energie poczatkowa
            ObliczaniePredkosci;
            delay 0.1;
         end loop;

      end Start;

   end Hamulec;



   task body Podloze is
      g : ada.numerics.float_random.Generator;
      ZmianaPodloza : Float;
      RandomFloat: Float;
   begin
      while PredkoscAuta > 0.0 loop
         RandomFloat := ada.numerics.float_random.Random(g);
         ZmianaPodloza := RandomFloat/10.0;

         --Put_Line("Zmiana podloza" & ZmianaPodloza'Img);
         if RandomFloat > 0.5 then
            WspoczynnikPodloza := WspoczynnikPodlozaPodstawa-ZmianaPodloza;
         else
            WspoczynnikPodloza := WspoczynnikPodlozaPodstawa+ZmianaPodloza;
         end if;

         delay 0.1;
      end loop;
   end Podloze;

   task body Czujnik is
      AktualnyWspolczynnik : Float := 0.0;
   begin
         while CzyHamulecWcisniety = false loop
         --delay 0.1;
         null;
         end loop;

         Put_Line("Czujnik zaczyna dzialac");
         while PredkoscAuta > 0.0 and ABSwlaczony = false loop
            -- co sekunde sprawdza czy kola sie nie zablokowaly
            -- sila hamowania przez m*g = aktualny_wsp
            AktualnyWspolczynnik := SilaHamowania/(PrzyspieszenieZiemskie*MasaAuta);
            -- if aktualny_wsp>podloze_wsp => kola zablokowane
            if AktualnyWspolczynnik>WspoczynnikPodloza then
               Put_Line("Kola zablokowane");
               ABSwlaczony := True;
            end if;
            -- wlacz abs
         end loop;
         -- dopoki aktualny_wsp>podloze_wsp zmniejszaj sile

         Put_Line("Czujnik przestaje dzialac");


   end Czujnik;

   task body SterownikABS is
      AktualnyWspolczynnik : Float := 0.8;
   begin
      while ABSwlaczony = false loop
         --delay 0.1;
                  null;
         end loop;
      Put_Line("Wlaczony ABS");

      --dopoki predkosc nie jest zero
      while PredkoscAuta > 0.0 loop
         -- dobieramy odpowiednia sile
         SilaHamowania := SilaHamowania+200.0;
         while AktualnyWspolczynnik>WspoczynnikPodloza loop
            SilaHamowania := SilaHamowania-100.0;
            AktualnyWspolczynnik := SilaHamowania/(PrzyspieszenieZiemskie*MasaAuta);
            --Put_Line("in");
         end loop;

         ObliczaniePredkosci;
         delay 0.1;

      end loop;
      Put_Line("koniec ABSu");
   end SterownikABS;


   H : Hamulec;
   Cz : Czujnik;
   S : SterownikABS;
   P : Podloze;
begin
   delay 3.0;
   H.Start(S,Cz);
end Main;
