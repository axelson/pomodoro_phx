import { format, parseISO } from "date-fns";

export function renderDateTimeInLocalTimezone() {
  renderShownDates();
}

function renderShownDates() {
  const items = document.querySelectorAll('[role~="local-datetime"]');
  items.forEach((item) => {
    const date = parseISO(item.dataset.datetime);

    const html =
      getDaysPassed(date) > 0
        ? format(date, "yyyy-MM-dd HH:mm:ss")
        : format(date, "HH:mm:ss");

    item.innerHTML = html;
  });
}

function getDaysPassed(startDate) {
  const currentDate = new Date();

  // Calculate the time difference in milliseconds
  const timeDifference = currentDate - startDate;

  // Convert milliseconds to days
  const daysPassed = Math.floor(timeDifference / (1000 * 60 * 60 * 24));

  return daysPassed;
}
