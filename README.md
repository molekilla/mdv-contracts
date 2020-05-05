## MDV API Contracts

### API Contracts

#### ExtensionEventRegistry
El registro de extension es el contrato del API de Extensiones.

#### IExtension
Interfaz que debe implementar una extension

#### IWModel
Un modelo requiere heredar de IWModel, esta interfaz es usada por WTemplate para acceder e interactuar con el modelo.

#### WFStorage
WFStorage contiene validadores y otros utilitarios.

#### WModels
Utilizado para construir modelos con RLP. El formato del modelo debe ser:

* Struct
- Struct Principal del WF
- Struct de Info de Step
- Status de Ejecucion de CRUD para Archivos
-
Ejemplo
```solidity
// DocumentPayload is the struct used by the client
struct DocumentPayload {
    RecetaDocument receta;
    StepInfo       stepInfo;
    uint256 documentStatus;
}
```
Adicionalmente, se mantiene internamente los datos de archivos como un mapping.

#### WStep
Libreria que contiene el modelo de Step o paso.


### Examples

La carpeta de `contract/examples` contiene un ejemplo de contrato para un WF de Recetas y Prescripciones.s

En `test` se encuentra el archivo de prueba del mismo, el cual contiene la definicion de creacio de un MDV WF.