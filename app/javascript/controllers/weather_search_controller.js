import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["zipFields", "cityStateFields", "form"]

  connect() {
    // Ensure initial mode matches the checked radio
    const selected = this._selectedMode()
    this._updateVisibility(selected)
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
}
