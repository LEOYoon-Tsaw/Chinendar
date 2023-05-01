# Chinese Time

[<img src="screenshots/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.svg" height="50">](https://apple.co/3LFIf7i)

## Backgrounds

Chinese calendar is a celestial calandar. The 2 most important rules are:

* New moon marks the start of a month
* Winter Solstice must fall in the Month 11

The average length of a month is 29.53 days, and length of a year is 365.25, the cannot divide each other, so comes leap month. Leap month does not have an Even Solar Term in it. Traditionally, leap month is calculated between the beginning of the new moon day to the day before the next new moon day, but this is local time dependent, in different timezone, new moon day may shift by up to 1 day, so the leap month can be very different whe calculated in different timezone. A way to eliminate locality is to calculate leap month between the exact new moon moments, thus leap month will be global, and does not depend on the local time. In this app, user can choose from either of the 2 methods.

Chinese time is consisted of Hours, Quarters and Subquarters. One Chinese hour is 2 hours, but they are divided into Small Hours, which corresponds to 1 hour. One Quarter is 100th of a day, which is 14.4 minutes. The 24 Small Hour and 100 Quarters consists of major time telling, by saying x Quarters after x Small Hour. One Quarter is further divided into 6 Subquarters, which is 2.4 minutes. Subquarter is the greatest common divisor of Small Hour and Quarter.

Besides calendar, the positions of the 5 major solar planets plus the Moon on elliptical plane, plus sunrise, sunset, moonrise, moonset time are also important elements in Chinese calendar. These planet positions, especially Jupiter and Saturn, are traditionally used to take note of the year. Here, they are marked by colored squares on several rings.

## Information displayed

1. Chinese calendar month, day, hour and quarter
2. Ecliptic positions of Mercury, Venus, Mars, Jupiter, Saturn and Moon
3. Exact moments of New Moon, Full Moon, and 24 Solar Terms
4. Sunrise, set, astronomical noon and midnight, as well as moonrise, set, and at meridian time

## Screenshots

<p align="middle">
  <img src="/screenshots/mac.png" alt="Screenshot in Mac" title="Mac Screenshot" height="300"/>
  <img src="/screenshots/iphone.png" alt="Screenshot in iPhone" title="iPhone Screenshot" height="300"/>
</p>

The circles from outermost to innermost are Year, Month, Day, Hour. Each will progress as time goes by. On the year ring, 24 Solar Terms and all New Moons and Full Moons are indicated by ticks. If any of these celestial event fall in a given month/day/hour, they are marked by a semi-sphese on the inner circles as well. At the center is the text description of the date and time.

The Ecliptic positions of Mercury, Venus, Mars, Jupiter, Saturn and Moon are also shown as marks on the outer-most ring. Sunrise, sunset, and moonrise, moonset are marked in the 2 inner most rings. Geographic location is needed for this calculatioin, so the app will ask for permision upon first launch. If you feel unconfortable about reading location, you can also provide it manually.

Many UI elements are configurable, like the color of the rings and marks, along with the displayed date, time, location, and timezone.
Location and timezone are **not** stored anywhere, while other configurations like the colors will be stored so that they can be used upon next launch.

## License

GPL 3.0
