import { format, parseISO } from "date-fns";

export function renderDateTimeInLocalTimezone() {
  renderShownDates();
  renderLocalDateForms();
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

function renderLocalDateForms() {
  const form = document.getElementById("torch-form");
  if (!form) return;

  const datetimeGroups = form.querySelectorAll(
    '[role~="datetime-local-form-group"]',
  );

  iterateDateTimeGroups(datetimeGroups, (localDateTimeInput) => {
    const date = parseISO(localDateTimeInput.value + "Z");
    const newVal = format(date, "yyyy-MM-dd HH:mm");
    localDateTimeInput.value = newVal;
  });

  form.addEventListener("submit", function (e) {
    e.preventDefault();

    datetimeGroups.forEach((dateTimeGroup) => {
      const localDateTimeInput = dateTimeGroup.querySelector(
        'input[type="datetime-local"]',
      );

      if (!localDateTimeInput.value) return;
      const localDateTime = new Date(localDateTimeInput.value);

      localDateTimeInput.value = toDateTimeISO(localDateTime);
    });

    form.submit();
  });
}

function iterateDateTimeGroups(datetimeGroups, fun) {
  datetimeGroups.forEach((dateTimeGroup) => {
    const localDateTimeInput = dateTimeGroup.querySelector(
      'input[type="datetime-local"]',
    );

    // Skip values that are not set
    if (!localDateTimeInput.value) return;
    fun(localDateTimeInput);
  });
}

function toDateTimeISO(date) {
  const isoDateString = date.toISOString();
  return `${isoDateString.substring(0, 10)} ${isoDateString.substring(11, 19)}`;
}

function getDaysPassed(startDate) {
  const currentDate = new Date();

  // Calculate the time difference in milliseconds
  const timeDifference = currentDate - startDate;

  // Convert milliseconds to days
  const daysPassed = Math.floor(timeDifference / (1000 * 60 * 60 * 24));

  return daysPassed;
}
