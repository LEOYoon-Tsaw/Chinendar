# Chinese Time

## Backgrounds

Chinese calendar is a celestial calandar. The 2 most important rules are:

* New moon marks the start of a month
* Winter Solstice must fall in the Month 11

The average length of a month is 29.53 days, and length of a year is 365.25, the cannot divide each other, so comes leap month. Leap month does not have an Even Solar Term in it. Traditionally, leap month is calculated between the beginning of the new moon day to the day before the next new moon day, but this is local time dependent, in different timezone, new moon day may shift by up to 1 day, so the leap month can be very different whe calculated in different timezone. A way to eliminate locality is to calculate leap month between the exact new moon moments, thus leap month will be global, and does not depend on the local time. In this app, user can choose from either of the 2 methods.

Chinese time is consisted of Hours, Quarters and Subquarters. One Chinese hour is 2 hours, but they are divided into Small Hours, which corresponds to 1 hour. One Quarter is 100th of a day, which is 14.4 minutes. The 24 Small Hour and 100 Quarters consists of major time telling, by saying x Quarters after x Small Hour. One Quarter is further divided into 6 Subquarters, which is 2.4 minutes. Subquarter is the greatest common divisor of Small Hour and Quarter.

## Screenshots

<p align="middle">
  <img src="/screenshots/empty.png" alt="New Start" title="New Start" width="350"/>
  <img src="/screenshots/full.png" alt="End of Circle" title="End of Circle" width="350"/>
</p>

The circles from outermost to innermost are Year, Month, Day, Hour. Each will progress as time goes by. On the year ring, 24 Solar Terms and all New Moons and Full Moons are indicated by ticks. If any of these celestial event fall in a given month/day/hour, they are marked by a semi-sphese on the inner circles as well. At the center is the text description of the date and time.

<p align="middle">
  <img src="/screenshots/config.png" alt="Configuration" title="Configuration" width="350"/>
</p>

Many UI elements are configurable, along with the displayed date and time, and timezone.

## License

GPL 3.0
