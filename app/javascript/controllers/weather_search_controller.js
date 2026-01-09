import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zipFields", "cityStateFields", "form", "zip", "city", "state"]

  connect() {
    // Ensure initial mode matches the checked radio
    const selected = this._selectedMode()
    this._updateVisibility(selected)

    // If a weather result is present on the page, reset the form inputs
    const resultEl = document.getElementById('weather-result')
    if (resultEl) {
      this.resetForm()
    }
  }

  modeChange(event) {
    const mode = event.target.value
    this._updateVisibility(mode)
  }

  _selectedMode() {
    const checked = this.element.querySelector('input[name="mode"]:checked')
    return checked ? checked.value : 'zip'
  }

  _updateVisibility(mode) {
    if (mode === 'zip') {
      this.zipFieldsTarget.style.display = ''
      this.cityStateFieldsTarget.style.display = 'none'
    } else {
      this.zipFieldsTarget.style.display = 'none'
      this.cityStateFieldsTarget.style.display = ''
    }
  }

  resetForm() {
    // Clear inputs so the form appears reset after a submit that returned results
    if (this.hasZipTarget) this.zipTarget.value = ''
    if (this.hasCityTarget) this.cityTarget.value = ''
    if (this.hasStateTarget) this.stateTarget.value = ''

    // Do not change the radio selection — preserve the user's selected mode
  }
}
